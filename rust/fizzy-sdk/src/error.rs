//! The one error type every call answers with, its categories and their exit codes.

use std::fmt;

use serde::de::DeserializeOwned;

use crate::http::{HeaderMap, Method, StatusCode};

/// The call succeeded.
pub const EXIT_OK: i32 = 0;
/// Invalid arguments or flags.
pub const EXIT_USAGE: i32 = 1;
/// Resource not found.
pub const EXIT_NOT_FOUND: i32 = 2;
/// Not authenticated.
pub const EXIT_AUTH: i32 = 3;
/// Access denied.
pub const EXIT_FORBIDDEN: i32 = 4;
/// Rate limited (429).
pub const EXIT_RATE_LIMIT: i32 = 5;
/// Connection, DNS or timeout failure.
pub const EXIT_NETWORK: i32 = 6;
/// The server returned an error.
pub const EXIT_API: i32 = 7;
/// A name matched more than one record.
pub const EXIT_AMBIGUOUS: i32 = 8;
/// The server rejected the contents of the request (422).
pub const EXIT_VALIDATION: i32 = 9;

/// The most of a failure's body an error keeps, mirroring Go's `MaxErrorBodyBytes`. A body
/// past it is kept up to the bound and no further: an error is diagnostic, and a server
/// answering a refusal with a megabyte of anything has said everything useful long before.
pub const MAX_ERROR_BODY_BYTES: usize = 10 * 1024;

/// The most of a server's own message an error's hint carries, mirroring Go's
/// `MaxErrorMessageBytes`. A longer one is cut and ends in `...`.
pub const MAX_ERROR_MESSAGE_BYTES: usize = 500;

/// Machine-readable error categories, shared with the other Fizzy SDKs.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[non_exhaustive]
pub enum ErrorCode {
    /// The call was built wrong: a bad argument, a plain-HTTP endpoint, a missing account.
    Usage,
    /// 404.
    NotFound,
    /// 401, or no credentials to send.
    AuthRequired,
    /// 403.
    Forbidden,
    /// 429, or the client's own rate limiter.
    RateLimit,
    /// No answer came back: connection, DNS, timeout, cancellation.
    Network,
    /// The server answered with a failure the other codes do not name, including every 5xx,
    /// and the calls the SDK refused for itself — see [`Error::refusal`].
    ApiError,
    /// 422.
    Validation,
    /// A name matched more than one record.
    Ambiguous,
}

impl ErrorCode {
    /// The code as the other SDKs spell it: `auth_required`, `rate_limit`.
    pub fn as_str(&self) -> &'static str {
        match self {
            ErrorCode::Usage => "usage",
            ErrorCode::NotFound => "not_found",
            ErrorCode::AuthRequired => "auth_required",
            ErrorCode::Forbidden => "forbidden",
            ErrorCode::RateLimit => "rate_limit",
            ErrorCode::Network => "network",
            ErrorCode::ApiError => "api_error",
            ErrorCode::Validation => "validation",
            ErrorCode::Ambiguous => "ambiguous",
        }
    }

    /// The process exit status a command should end with for this category.
    pub fn exit_code(&self) -> i32 {
        match self {
            ErrorCode::Usage => EXIT_USAGE,
            ErrorCode::NotFound => EXIT_NOT_FOUND,
            ErrorCode::AuthRequired => EXIT_AUTH,
            ErrorCode::Forbidden => EXIT_FORBIDDEN,
            ErrorCode::RateLimit => EXIT_RATE_LIMIT,
            ErrorCode::Network => EXIT_NETWORK,
            ErrorCode::ApiError => EXIT_API,
            ErrorCode::Validation => EXIT_VALIDATION,
            ErrorCode::Ambiguous => EXIT_AMBIGUOUS,
        }
    }
}

impl fmt::Display for ErrorCode {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

/// A call the SDK turned away itself, before anything was sent. It shares
/// [`ErrorCode::ApiError`] or [`ErrorCode::RateLimit`] with the server's own refusals and
/// is told apart by carrying no HTTP status and one of these.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[non_exhaustive]
pub enum Refusal {
    /// The scope's circuit breaker is open. See [`crate::resilience`].
    CircuitOpen,
    /// The scope already has as many calls in flight as its bulkhead allows.
    BulkheadFull,
    /// The client's own rate limiter has no token to spend.
    RateLimited,
}

/// The error every SDK call can answer with.
#[derive(Debug)]
pub struct Error {
    code: ErrorCode,
    message: String,
    hint: Option<String>,
    http_status: Option<u16>,
    retryable: bool,
    request_id: Option<String>,
    refusal: Option<Refusal>,
    source: Option<Box<dyn std::error::Error + Send + Sync>>,
    response_too_large: bool,
    /// What Fizzy answered the failure with, kept whole so a caller can read the server's
    /// own account of the refusal. See [`Error::body`]. A boxed slice rather than a
    /// [`bytes::Bytes`]: an error is never cloned, and half the width keeps every `Result`
    /// in the crate under clippy's `result_large_err` bound.
    body: Option<Box<[u8]>>,
}

impl Error {
    /// An error of a category, with a message.
    pub fn new(code: ErrorCode, message: impl Into<String>) -> Error {
        Error {
            code,
            message: message.into(),
            hint: None,
            http_status: None,
            retryable: false,
            request_id: None,
            refusal: None,
            source: None,
            response_too_large: false,
            body: None,
        }
    }

    /// The call was built wrong.
    pub fn usage(message: impl Into<String>) -> Error {
        Error::new(ErrorCode::Usage, message)
    }

    /// The call was built wrong, and here is what to do about it.
    pub fn usage_with_hint(message: impl Into<String>, hint: impl Into<String>) -> Error {
        Error::usage(message).with_hint(hint)
    }

    /// A record that is not there.
    pub fn not_found(resource: &str, identifier: impl fmt::Display) -> Error {
        Error::new(
            ErrorCode::NotFound,
            format!("{resource} not found: {identifier}"),
        )
        .with_status(404)
    }

    /// Credentials missing or refused.
    pub fn auth(message: impl Into<String>) -> Error {
        Error::new(ErrorCode::AuthRequired, message).with_status(401)
    }

    /// Access denied.
    pub fn forbidden(message: impl Into<String>) -> Error {
        Error::new(ErrorCode::Forbidden, message).with_status(403)
    }

    /// Access denied for want of scope, as a write answered 403 usually is.
    pub fn forbidden_scope() -> Error {
        Error::forbidden("Access denied: insufficient scope")
            .with_hint("Re-authenticate with full scope")
    }

    /// The rate-limit error a caller raises for itself, worded the way the other SDKs word
    /// theirs: "Rate limited". A 429 that came back from Fizzy reads "rate limited - try
    /// again later" instead — see [`Error::from_response`].
    pub fn rate_limit(retry_after: Option<u64>) -> Error {
        Error::new(ErrorCode::RateLimit, "Rate limited")
            .with_hint(retry_hint(retry_after))
            .with_status(429)
            .retryable()
    }

    /// The client's own rate limiter refused a call, so nothing was sent.
    pub fn rate_limited() -> Error {
        Error::new(ErrorCode::RateLimit, "rate limit exceeded").refusing_as(Refusal::RateLimited)
    }

    /// The scope's circuit breaker is open, so the SDK refused the call itself.
    pub fn circuit_open() -> Error {
        Error::new(ErrorCode::ApiError, "circuit breaker is open").refusing_as(Refusal::CircuitOpen)
    }

    /// The scope already has as many calls in flight as its bulkhead allows.
    pub fn bulkhead_full() -> Error {
        Error::new(ErrorCode::ApiError, "bulkhead is full").refusing_as(Refusal::BulkheadFull)
    }

    /// The caller dropped the future before it finished — a `tokio::time::timeout` that
    /// expired, a `select!` that took another branch. Nobody is waiting for this error: it
    /// is what the operation hooks are told the call ended as, so the bookkeeping every
    /// layer keeps per operation is closed out rather than left open.
    ///
    /// It is a [`ErrorCode::Network`] because that is what a call that never got an answer
    /// is. It is not retryable: there is nobody left to answer.
    pub fn cancelled() -> Error {
        Error::new(ErrorCode::Network, "operation cancelled")
    }

    /// No answer came back.
    pub fn network(source: impl std::error::Error + Send + Sync + 'static) -> Error {
        Error::new(ErrorCode::Network, "Network error")
            .with_hint(source.to_string())
            .retryable()
            .with_source(source)
    }

    /// The server answered with a failure.
    pub fn api(status: u16, message: impl Into<String>) -> Error {
        Error::new(ErrorCode::ApiError, message).with_status(status)
    }

    /// A body the client refused to read, because reading it whole is what the caller
    /// would have gone on to do. It carries no HTTP status of its own: the answer never
    /// arrived in full, so there is nothing to report about it but the refusal.
    pub fn response_too_large(limit: usize, method: &Method, path: &str) -> Error {
        Error {
            response_too_large: true,
            ..Error::api(
                0,
                format!("{method} {path}: response body exceeds {limit} bytes"),
            )
        }
    }

    /// Puts a refusal behind the error a status maps to, so a body too large to read on a
    /// non-2xx answer still reports the status the answer carried.
    pub(crate) fn refusing(mut self, refusal: Error) -> Error {
        self.response_too_large = refusal.response_too_large;
        if self.hint.is_none() {
            self.hint = Some(refusal.to_string());
        }
        self.with_source(refusal)
    }

    /// The messages the server itself produced, joined. With none of them the error still
    /// says something: "validation error".
    pub fn validation(messages: &[String]) -> Error {
        let mut message = messages.join("; ");
        if message.is_empty() {
            message = "validation error".to_string();
        }
        Error::new(ErrorCode::Validation, message).with_status(422)
    }

    /// A name that matched more than one record. Up to five matches are named in the hint;
    /// beyond that the only useful advice is to narrow the search.
    pub fn ambiguous(resource: &str, matches: &[String]) -> Error {
        let hint = match matches.len() {
            1..=5 => format!("Did you mean: {}", matches.join(", ")),
            _ => "Be more specific".to_string(),
        };
        Error::new(ErrorCode::Ambiguous, format!("Ambiguous {resource}")).with_hint(hint)
    }

    /// Wraps an error from outside the SDK as an API error that reads the way the original
    /// did, for the callers that have to answer with this type and nothing better fits.
    pub fn from_std(source: impl std::error::Error + Send + Sync + 'static) -> Error {
        Error::new(ErrorCode::ApiError, source.to_string()).with_source(source)
    }

    /// Maps a non-2xx response onto the SDK's error vocabulary. The hint carries whatever
    /// message the server put in the body, when it sent one, and the body itself is kept on
    /// the error for a caller that needs more of it than a hint — see [`Error::body`].
    pub fn from_response(
        status: StatusCode,
        method: &Method,
        headers: &HeaderMap,
        body: &[u8],
    ) -> Error {
        let error = match status.as_u16() {
            401 => Error::auth("Authentication failed"),
            403 if method != Method::GET => Error::forbidden_scope(),
            403 => Error::forbidden("Access denied"),
            404 => Error::new(ErrorCode::NotFound, "Resource not found").with_status(404),
            422 => Error::new(ErrorCode::Validation, "Validation failed").with_status(422),
            429 => Error::new(ErrorCode::RateLimit, "Rate limited - try again later")
                .with_hint(retry_hint(retry_after_seconds(headers)))
                .with_status(429)
                .retryable(),
            code => {
                let error = Error::api(code, format!("API error: {status}"));
                if status.is_server_error() {
                    error.retryable()
                } else {
                    error
                }
            }
        };
        let error = match headers
            .get("x-request-id")
            .and_then(|value| value.to_str().ok())
        {
            Some(request_id) => error.with_request_id(request_id),
            None => error,
        };
        let mut error = match (error.hint.is_none(), server_message(body)) {
            (true, Some(message)) => error.with_hint(message),
            _ => error,
        };
        if !body.is_empty() {
            let kept = body.len().min(MAX_ERROR_BODY_BYTES);
            error.body = Some(Box::from(&body[..kept]));
        }
        error
    }

    /// Adds advice.
    pub fn with_hint(mut self, hint: impl Into<String>) -> Error {
        self.hint = Some(hint.into());
        self
    }

    /// Records the HTTP status.
    pub fn with_status(mut self, status: u16) -> Error {
        self.http_status = Some(status);
        self
    }

    /// Records the server's request id.
    pub fn with_request_id(mut self, request_id: impl Into<String>) -> Error {
        self.request_id = Some(request_id.into());
        self
    }

    /// Records what caused this.
    pub fn with_source(mut self, source: impl std::error::Error + Send + Sync + 'static) -> Error {
        self.source = Some(Box::new(source));
        self
    }

    /// Marks the call as worth resending.
    pub fn retryable(mut self) -> Error {
        self.retryable = true;
        self
    }

    fn refusing_as(mut self, refusal: Refusal) -> Error {
        self.refusal = Some(refusal);
        self
    }

    /// The category.
    pub fn code(&self) -> ErrorCode {
        self.code
    }

    /// Whether the error is of this category.
    pub fn is_code(&self, code: ErrorCode) -> bool {
        self.code == code
    }

    /// The process exit status a command should end with for this error.
    pub fn exit_code(&self) -> i32 {
        self.code.exit_code()
    }

    /// What went wrong.
    pub fn message(&self) -> &str {
        &self.message
    }

    /// What to do about it, when there is advice.
    pub fn hint(&self) -> Option<&str> {
        self.hint.as_deref()
    }

    /// The HTTP status, when the server answered.
    pub fn http_status(&self) -> Option<u16> {
        self.http_status
    }

    /// Whether resending would be worth trying.
    pub fn is_retryable(&self) -> bool {
        self.retryable
    }

    /// The server's `X-Request-Id`, when it sent one.
    pub fn request_id(&self) -> Option<&str> {
        self.request_id.as_deref()
    }

    /// Which of the SDK's own layers turned the call away, when one did.
    pub fn refusal(&self) -> Option<Refusal> {
        self.refusal
    }

    /// The answer was longer than the client will hold in memory, whether that refusal is
    /// the error itself or sits behind the status the answer carried.
    pub fn is_response_too_large(&self) -> bool {
        self.response_too_large
    }

    /// What Fizzy answered the failure with, up to [`MAX_ERROR_BODY_BYTES`]. A 422 describes
    /// the fields it objected to in the body, and this is where that account is kept. It is
    /// `None` when the answer carried no body, when the SDK raised the error itself, and
    /// when the body was too long to read.
    pub fn body(&self) -> Option<&[u8]> {
        self.body.as_deref()
    }

    /// The failure body read as `T`, or `None` when there is no body or it does not read as
    /// one.
    pub fn body_json<T: DeserializeOwned>(&self) -> Option<T> {
        serde_json::from_slice(self.body()?).ok()
    }
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match &self.hint {
            Some(hint) => write!(f, "{}: {hint}", self.message),
            None => f.write_str(&self.message),
        }
    }
}

impl std::error::Error for Error {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        self.source
            .as_deref()
            .map(|source| source as &(dyn std::error::Error + 'static))
    }
}

impl From<serde_json::Error> for Error {
    fn from(error: serde_json::Error) -> Error {
        Error::api(0, "unexpected JSON")
            .with_hint(error.to_string())
            .with_source(error)
    }
}

impl From<url::ParseError> for Error {
    fn from(error: url::ParseError) -> Error {
        Error::usage(format!("invalid URL: {error}")).with_source(error)
    }
}

fn retry_hint(retry_after: Option<u64>) -> String {
    match retry_after {
        Some(seconds) if seconds > 0 => format!("Try again in {seconds} seconds"),
        _ => "Try again later".to_string(),
    }
}

/// The wait `Retry-After` asks for, in seconds. The header carries either a count of
/// seconds or the HTTP-date the wait is over, and a date already past asks for no wait at
/// all.
pub(crate) fn retry_after_seconds(headers: &HeaderMap) -> Option<u64> {
    let asked = headers.get("retry-after")?.to_str().ok()?.trim();
    if let Ok(seconds) = asked.parse::<i64>() {
        u64::try_from(seconds).ok()
    } else {
        let until = chrono::DateTime::parse_from_rfc2822(asked).ok()?;
        seconds_until(until.with_timezone(&chrono::Utc), chrono::Utc::now())
    }
}

/// The whole seconds from `now` until `until`, counting a started second as one: the date
/// names the moment the wait is over, so rounding down would resend before it.
fn seconds_until(
    until: chrono::DateTime<chrono::Utc>,
    now: chrono::DateTime<chrono::Utc>,
) -> Option<u64> {
    let left = until.signed_duration_since(now);
    let whole = left.num_seconds();
    let started = left > chrono::Duration::seconds(whole);
    u64::try_from(if started { whole + 1 } else { whole }).ok()
}

fn server_message(body: &[u8]) -> Option<String> {
    let value: serde_json::Value = serde_json::from_slice(body).ok()?;
    let message = value
        .get("message")
        .or_else(|| value.get("error"))?
        .as_str()?;
    Some(truncate(message, MAX_ERROR_MESSAGE_BYTES))
}

/// Cuts a message to `limit` characters, saying so with a trailing `...`, the way Go's
/// `truncateString` does.
pub(crate) fn truncate(message: &str, limit: usize) -> String {
    if message.chars().count() <= limit {
        message.to_string()
    } else {
        let kept: String = message.chars().take(limit.saturating_sub(3)).collect();
        format!("{kept}...")
    }
}

#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests {
    use super::*;
    use chrono::{DateTime, Duration, Utc};

    fn at(millis: i64) -> DateTime<Utc> {
        DateTime::from_timestamp_millis(1_700_000_000_000 + millis).unwrap()
    }

    #[test]
    fn a_started_second_counts_as_a_whole_one() {
        assert_eq!(seconds_until(at(2_000), at(0)), Some(2));
        assert_eq!(seconds_until(at(2_000), at(50)), Some(2));
        assert_eq!(seconds_until(at(2_000), at(1_050)), Some(1));
        assert_eq!(seconds_until(at(2_000), at(1_999)), Some(1));
        assert_eq!(
            seconds_until(at(2_000), at(0) - Duration::nanoseconds(1)),
            Some(3)
        );
    }

    #[test]
    fn a_date_already_past_asks_for_no_wait() {
        assert_eq!(seconds_until(at(0), at(0)), Some(0));
        assert_eq!(seconds_until(at(0), at(500)), Some(0));
        assert_eq!(seconds_until(at(0), at(1_500)), None);
    }

    #[test]
    fn retry_after_reads_seconds_and_dates() {
        let mut headers = HeaderMap::new();
        headers.insert("retry-after", "7".parse().unwrap());
        assert_eq!(retry_after_seconds(&headers), Some(7));
        headers.insert(
            "retry-after",
            "Wed, 21 Oct 2015 07:28:00 GMT".parse().unwrap(),
        );
        assert_eq!(retry_after_seconds(&headers), None);
        headers.insert("retry-after", "soon".parse().unwrap());
        assert_eq!(retry_after_seconds(&headers), None);
    }

    #[test]
    fn every_code_has_an_exit_status_and_a_name() {
        let codes = [
            (ErrorCode::Usage, "usage", 1),
            (ErrorCode::NotFound, "not_found", 2),
            (ErrorCode::AuthRequired, "auth_required", 3),
            (ErrorCode::Forbidden, "forbidden", 4),
            (ErrorCode::RateLimit, "rate_limit", 5),
            (ErrorCode::Network, "network", 6),
            (ErrorCode::ApiError, "api_error", 7),
            (ErrorCode::Validation, "validation", 9),
            (ErrorCode::Ambiguous, "ambiguous", 8),
        ];
        for (code, name, exit) in codes {
            assert_eq!(code.as_str(), name);
            assert_eq!(code.exit_code(), exit);
        }
    }

    #[test]
    fn refusals_carry_no_status_and_say_which_layer() {
        assert_eq!(Error::circuit_open().refusal(), Some(Refusal::CircuitOpen));
        assert_eq!(
            Error::bulkhead_full().refusal(),
            Some(Refusal::BulkheadFull)
        );
        assert_eq!(Error::rate_limited().refusal(), Some(Refusal::RateLimited));
        assert_eq!(Error::rate_limited().code(), ErrorCode::RateLimit);
        assert_eq!(Error::circuit_open().http_status(), None);
        assert_eq!(Error::api(500, "boom").refusal(), None);
    }
}
