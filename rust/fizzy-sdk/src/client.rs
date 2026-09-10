//! The client, its builder, the account-scoped client and the request pipeline they
//! share: hooks, credentials, retries, redirects and the response cache.

use std::borrow::Cow;
use std::fmt::Display;
use std::sync::Arc;
use std::time::{Duration, Instant};

use bytes::Bytes;
use serde::de::DeserializeOwned;
use url::Url;

use crate::auth::{AuthStrategy, BearerAuth, CookieAuth, StaticTokenProvider, TokenProvider};
use crate::cache::{CachedResponse, FileCache, ResponseCache, cache_key};
use crate::config::Config;
use crate::error::{Error, ErrorCode, MAX_ERROR_BODY_BYTES, retry_after_seconds};
use crate::http::header::{
    ACCEPT, AUTHORIZATION, CONTENT_LENGTH, CONTENT_TYPE, COOKIE, IF_NONE_MATCH, USER_AGENT,
};
use crate::http::{
    Body, HeaderMap, HeaderValue, HttpClient, Method, Request, Response as HttpResponse, StatusCode,
};
use crate::observability::{
    Hooks, NoopHooks, OperationInfo, OperationState, RequestInfo, RequestResult,
};
use crate::operation::{DEFAULT_RETRY_ON, Operation, RetryPolicy};
use crate::pagination::Page;
use crate::route::Route;
use crate::security::{is_same_origin, require_secure_endpoint};
use crate::version::default_user_agent;

/// How long the shipped HTTP client gives an answer to arrive.
pub const DEFAULT_TIMEOUT: Duration = Duration::from_secs(30);
/// How many times a raw call is sent, the first attempt included, and the ceiling on what a
/// modelled route may ask for. Three, as the behavior model gives every retried operation
/// and as the Go client counts its `MaxRetries`.
pub const DEFAULT_MAX_ATTEMPTS: u32 = 3;
/// The first backoff for a raw call.
pub const DEFAULT_BASE_DELAY: Duration = Duration::from_secs(1);
/// The longest the client waits between attempts, however many it has made. The backoff's
/// job is to stop hammering, and thirty seconds does it; a caller who raised the retry
/// count would otherwise be waiting minutes on a server that is not coming back. Move it
/// with [`ClientBuilder::max_delay`].
pub const DEFAULT_MAX_DELAY: Duration = Duration::from_secs(30);
/// The longest `Retry-After` the client sits out. Past it the answer is handed back as the
/// rate-limit error it is, with the wait in the hint, rather than the call blocking for
/// an hour. Move it with [`ClientBuilder::max_retry_after`].
pub const DEFAULT_MAX_RETRY_AFTER: Duration = Duration::from_secs(60);
/// The most random time added to a backoff.
pub const DEFAULT_MAX_JITTER: Duration = Duration::from_millis(100);
/// How many pages a walk reads before stopping.
pub const DEFAULT_MAX_PAGES: usize = 10_000;
/// The most of an answer the client holds in memory.
pub const DEFAULT_MAX_RESPONSE_BODY_BYTES: usize = 10 << 20;

/// How many redirects one request may go through before the client gives up on it.
const MAX_REDIRECTS: usize = 10;

/// A Fizzy client: one set of credentials on one origin. Most of the API is scoped to an
/// account, reached with [`Client::for_account`]; what is not — sessions, identity, access
/// tokens — hangs off the client itself.
///
/// Clients are cheap to clone and share their connection pool, credentials and cache.
#[derive(Clone)]
pub struct Client {
    pub(crate) shared: Arc<Shared>,
}

pub(crate) struct Shared {
    pub(crate) config: Config,
    pub(crate) base_url: Url,
    pub(crate) http: Arc<dyn HttpClient>,
    pub(crate) auth: Arc<dyn AuthStrategy>,
    pub(crate) user_agent: String,
    pub(crate) max_attempts: u32,
    pub(crate) base_delay: Duration,
    pub(crate) max_delay: Duration,
    pub(crate) max_retry_after: Duration,
    pub(crate) max_jitter: Duration,
    pub(crate) max_pages: usize,
    pub(crate) max_response_body_bytes: usize,
    pub(crate) cache: Option<Arc<dyn ResponseCache>>,
    pub(crate) hooks: Arc<dyn Hooks>,
}

/// A client scoped to one account: every path it sends starts with the account id. Made
/// with [`Client::for_account`].
#[derive(Clone)]
pub struct AccountClient {
    client: Client,
    account_id: String,
}

impl std::fmt::Debug for Client {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Client")
            .field("base_url", &self.shared.base_url.as_str())
            .field("user_agent", &self.shared.user_agent)
            .finish_non_exhaustive()
    }
}

impl std::fmt::Debug for AccountClient {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("AccountClient")
            .field("account_id", &self.account_id)
            .field("client", &self.client)
            .finish()
    }
}

impl AccountClient {
    /// The client underneath.
    pub fn client(&self) -> &Client {
        &self.client
    }

    /// The account every call is scoped to.
    pub fn account_id(&self) -> &str {
        &self.account_id
    }

    /// The scope generated services send through.
    pub fn scope(&self) -> Scope<'_> {
        Scope {
            client: &self.client,
            account_id: Some(&self.account_id),
        }
    }
}

/// What a generated service sends through: the client, and the account when there is one.
#[derive(Clone, Copy)]
pub struct Scope<'a> {
    client: &'a Client,
    account_id: Option<&'a str>,
}

impl<'a> Scope<'a> {
    /// The client underneath.
    pub fn client(&self) -> &'a Client {
        self.client
    }

    /// The account, when the scope has one.
    pub fn account_id(&self) -> Option<&'a str> {
        self.account_id
    }

    /// Starts a request for a modelled route. An account-scoped route needs an account,
    /// and asks for one as a usage error rather than sending a path with a hole in it.
    pub fn operation(
        &self,
        route: &'static Route,
        params: &[&dyn Display],
    ) -> Result<Operation, Error> {
        if route.account_scoped && self.account_id.is_none() {
            return Err(Error::usage_with_hint(
                format!("{} needs an account", route.id),
                "reach it through Client::for_account",
            ));
        }
        let account_id = if route.account_scoped {
            self.account_id
        } else {
            None
        };
        Operation::for_route(route, account_id, params)
    }
}

/// What came back from Fizzy, before it is decoded.
#[derive(Clone)]
#[non_exhaustive]
pub struct Response {
    /// The status.
    pub status: StatusCode,
    /// The headers.
    pub headers: HeaderMap,
    /// The body, read whole.
    pub body: Bytes,
    /// Where the answer came from, once any redirects were followed.
    pub url: Url,
    /// The body came out of the response cache: Fizzy answered 304 and the client read the
    /// entry it was holding.
    pub from_cache: bool,
}

/// The body never prints, and the headers print redacted: an answer may carry a session
/// cookie or a person's details, and `{:?}` of a response is the kind of thing that ends
/// up in a log.
impl std::fmt::Debug for Response {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Response")
            .field("status", &self.status)
            .field("headers", &crate::security::redact_headers(&self.headers))
            .field("body_len", &self.body.len())
            .field("url", &self.url.as_str())
            .field("from_cache", &self.from_cache)
            .finish()
    }
}

impl Response {
    /// Decodes the body as JSON. A body that does not read as `T` is an API error carrying
    /// the answer's status and request id, so the failure can still be traced.
    pub fn json<T: DeserializeOwned>(&self) -> Result<T, Error> {
        let status = self.status.as_u16();
        let error = if self.body.is_empty() {
            Error::api(status, "empty response body")
        } else {
            match serde_json::from_slice(&self.body) {
                Ok(value) => return Ok(value),
                Err(error) => Error::api(status, "unexpected JSON")
                    .with_hint(error.to_string())
                    .with_source(error),
            }
        };
        Err(match self.header("x-request-id") {
            Some(request_id) => error.with_request_id(request_id),
            None => error,
        })
    }

    /// A header, when it is there and reads as text.
    pub fn header(&self, name: &str) -> Option<&str> {
        self.headers.get(name).and_then(|value| value.to_str().ok())
    }
}

/// How a raw call is sent, where the defaults are not what the caller wants.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct RequestOptions {
    /// Send once, whatever the method.
    pub no_retry: bool,
    /// Resend a POST the way a GET is resent.
    pub idempotent: bool,
}

impl RequestOptions {
    /// The defaults: everything but a POST is retried.
    pub fn new() -> RequestOptions {
        RequestOptions::default()
    }

    /// Send once.
    pub fn no_retry(mut self) -> RequestOptions {
        self.no_retry = true;
        self
    }

    /// Treat the call as safe to resend.
    pub fn idempotent(mut self) -> RequestOptions {
        self.idempotent = true;
        self
    }

    pub(crate) fn apply(&self, mut operation: Operation) -> Operation {
        if self.idempotent {
            operation.idempotent(true);
        }
        if self.no_retry {
            operation.no_retry();
        }
        operation
    }
}

/// Builds a [`Client`].
pub struct ClientBuilder {
    config: Config,
    auth: Option<Arc<dyn AuthStrategy>>,
    http: Option<Arc<dyn HttpClient>>,
    user_agent: String,
    timeout: Duration,
    max_attempts: u32,
    base_delay: Duration,
    max_delay: Duration,
    max_retry_after: Duration,
    max_jitter: Duration,
    max_pages: usize,
    max_response_body_bytes: usize,
    cache: Option<Arc<dyn ResponseCache>>,
    pub(crate) hooks: Arc<dyn Hooks>,
}

impl ClientBuilder {
    /// A builder over a config, with nothing else decided.
    pub fn new(config: Config) -> ClientBuilder {
        ClientBuilder {
            config,
            auth: None,
            http: None,
            user_agent: default_user_agent(),
            timeout: DEFAULT_TIMEOUT,
            max_attempts: DEFAULT_MAX_ATTEMPTS,
            base_delay: DEFAULT_BASE_DELAY,
            max_delay: DEFAULT_MAX_DELAY,
            max_retry_after: DEFAULT_MAX_RETRY_AFTER,
            max_jitter: DEFAULT_MAX_JITTER,
            max_pages: DEFAULT_MAX_PAGES,
            max_response_body_bytes: DEFAULT_MAX_RESPONSE_BODY_BYTES,
            cache: None,
            hooks: Arc::new(NoopHooks),
        }
    }

    /// Sends `Authorization: Bearer` from a token provider.
    pub fn token_provider(self, provider: impl TokenProvider + 'static) -> ClientBuilder {
        self.auth_strategy(BearerAuth::new(provider))
    }

    /// Sends `Authorization: Bearer` with a fixed access token.
    pub fn access_token(self, token: impl Into<crate::types::SensitiveString>) -> ClientBuilder {
        self.token_provider(StaticTokenProvider::new(token))
    }

    /// Sends `Cookie: session_token=` with a fixed session token, as a magic-link login
    /// hands out.
    pub fn session_token(self, token: impl Into<crate::types::SensitiveString>) -> ClientBuilder {
        self.auth_strategy(CookieAuth::new(StaticTokenProvider::new(token)))
    }

    /// Puts credentials on with something of the caller's own.
    pub fn auth_strategy(mut self, strategy: impl AuthStrategy + 'static) -> ClientBuilder {
        self.auth = Some(Arc::new(strategy));
        self
    }

    /// Replaces the HTTP client every request goes out on. The one supplied must not
    /// follow redirects; see [`HttpClient`]. The timeout set on the builder is then ignored
    /// — a timeout belongs to the client that can enforce it.
    pub fn http_client(mut self, http: impl HttpClient + 'static) -> ClientBuilder {
        self.http = Some(Arc::new(http));
        self
    }

    /// Replaces the `User-Agent`.
    pub fn user_agent(mut self, user_agent: impl Into<String>) -> ClientBuilder {
        self.user_agent = user_agent.into();
        self
    }

    /// How long the HTTP client the SDK ships gives an answer to arrive. It has no effect on
    /// one supplied with [`ClientBuilder::http_client`].
    pub fn timeout(mut self, timeout: Duration) -> ClientBuilder {
        self.timeout = timeout;
        self
    }

    /// How many times a raw call is sent, the first attempt included, and the most a
    /// modelled route may be sent whatever the behavior model says. One sends everything
    /// once; zero reads as one.
    pub fn max_attempts(mut self, max_attempts: u32) -> ClientBuilder {
        self.max_attempts = max_attempts.max(1);
        self
    }

    /// The first backoff for a raw call.
    pub fn base_delay(mut self, base_delay: Duration) -> ClientBuilder {
        self.base_delay = base_delay;
        self
    }

    /// The longest wait between attempts, whatever the backoff or the route's own base
    /// delay would have made it.
    pub fn max_delay(mut self, max_delay: Duration) -> ClientBuilder {
        self.max_delay = max_delay;
        self
    }

    /// The longest `Retry-After` the client sits out before handing the answer back.
    pub fn max_retry_after(mut self, max_retry_after: Duration) -> ClientBuilder {
        self.max_retry_after = max_retry_after;
        self
    }

    /// The most random time added to a backoff. Zero makes the waits exact.
    pub fn max_jitter(mut self, max_jitter: Duration) -> ClientBuilder {
        self.max_jitter = max_jitter;
        self
    }

    /// How many pages a walk reads before stopping.
    pub fn max_pages(mut self, max_pages: usize) -> ClientBuilder {
        self.max_pages = max_pages;
        self
    }

    /// The most an answer may deliver before the client refuses to hold it. Zero asks for
    /// the default: the cap cannot be lifted, only moved.
    pub fn max_response_body_bytes(mut self, bytes: usize) -> ClientBuilder {
        self.max_response_body_bytes = bytes;
        self
    }

    /// Caches JSON reads by `ETag`. Without this, `config.cache_enabled` decides whether a
    /// [`FileCache`] in `config.cache_dir` is used.
    pub fn cache(mut self, cache: impl ResponseCache + 'static) -> ClientBuilder {
        self.cache = Some(Arc::new(cache));
        self
    }

    /// Reports every operation and every request the client makes. Several sets of hooks
    /// go on as one with [`crate::observability::ChainHooks`].
    pub fn hooks(mut self, hooks: impl Hooks + 'static) -> ClientBuilder {
        self.hooks = Arc::new(hooks);
        self
    }

    /// Builds the client, refusing a base URL that would carry credentials over plain HTTP
    /// anywhere but this machine.
    pub fn build(self) -> Result<Client, Error> {
        let base_url = parse_base_url(&self.config.base_url)?;
        let auth = self
            .auth
            .ok_or_else(|| Error::usage("a token provider or auth strategy is required"))?;
        if self.timeout.is_zero() {
            return Err(Error::usage("timeout must be greater than zero"));
        }
        if self.max_pages == 0 {
            return Err(Error::usage("max pages must be greater than zero"));
        }
        let http = match self.http {
            Some(http) => http,
            None => shipped_http_client(self.timeout)?,
        };
        let cache =
            match (self.cache, self.config.cache_enabled) {
                (Some(cache), _) => Some(cache),
                (None, true) => Some(Arc::new(FileCache::new(self.config.cache_dir.clone()))
                    as Arc<dyn ResponseCache>),
                (None, false) => None,
            };
        let max_response_body_bytes = match self.max_response_body_bytes {
            0 => DEFAULT_MAX_RESPONSE_BODY_BYTES,
            bytes => bytes,
        };
        let shared = Shared {
            config: self.config,
            base_url,
            http,
            auth,
            user_agent: self.user_agent,
            max_attempts: self.max_attempts,
            base_delay: self.base_delay.min(self.max_delay),
            max_delay: self.max_delay,
            max_retry_after: self.max_retry_after,
            max_jitter: self.max_jitter,
            max_pages: self.max_pages,
            max_response_body_bytes,
            cache,
            hooks: self.hooks,
        };
        Ok(Client {
            shared: Arc::new(shared),
        })
    }
}

impl Client {
    /// A builder over a config.
    pub fn builder(config: Config) -> ClientBuilder {
        ClientBuilder::new(config)
    }

    /// A client with the default settings and a bearer token, on the HTTP client the SDK
    /// ships. Without the `reqwest` feature there is no such client, and a
    /// [`ClientBuilder`] with an [`HttpClient`] of the application's own is the way in.
    #[cfg(feature = "reqwest")]
    #[cfg_attr(docsrs, doc(cfg(feature = "reqwest")))]
    pub fn new(config: Config, provider: impl TokenProvider + 'static) -> Result<Client, Error> {
        Client::builder(config).token_provider(provider).build()
    }

    /// The config the client was built from.
    pub fn config(&self) -> &Config {
        &self.shared.config
    }

    /// The origin every call goes to.
    pub fn base_url(&self) -> &Url {
        &self.shared.base_url
    }

    /// How many pages a walk reads before stopping.
    pub fn max_pages(&self) -> usize {
        self.shared.max_pages
    }

    /// A client scoped to one account. The id is checked for shape here — it goes into
    /// every path as one segment — and against Fizzy on the first call.
    pub fn for_account(&self, account_id: impl Into<String>) -> Result<AccountClient, Error> {
        let account_id = account_id.into();
        if account_id.is_empty()
            || account_id == "."
            || account_id == ".."
            || account_id.contains(['/', '?', '#', '%'])
            || account_id
                .chars()
                .any(|c| c.is_whitespace() || c.is_control())
        {
            return Err(Error::usage(format!("invalid account id {account_id:?}")));
        }
        Ok(AccountClient {
            client: self.clone(),
            account_id,
        })
    }

    /// A client scoped to the account the config names, when it names one.
    pub fn for_configured_account(&self) -> Result<AccountClient, Error> {
        match &self.shared.config.account {
            Some(account_id) => self.for_account(account_id.clone()),
            None => Err(Error::usage_with_hint(
                "no account configured",
                "set FIZZY_ACCOUNT or Config::account, or call Client::for_account",
            )),
        }
    }

    /// The scope the account-free services send through.
    pub fn scope(&self) -> Scope<'_> {
        Scope {
            client: self,
            account_id: None,
        }
    }

    /// Starts a request for one of the modelled routes that needs no account. Generated
    /// service methods go through [`Scope::operation`]; reach for this directly only to
    /// add headers or query parameters they do not expose.
    pub fn operation(
        &self,
        route: &'static Route,
        params: &[&dyn Display],
    ) -> Result<Operation, Error> {
        self.scope().operation(route, params)
    }

    /// Starts a request for a path the model does not cover. The path is relative to the
    /// base URL and gets the same credentials and retry treatment as a modelled one.
    pub fn request(&self, method: Method, path: impl Into<String>) -> Operation {
        Operation::raw(method, path.into())
    }

    /// Sends an operation and decodes its JSON body.
    pub async fn send<T: DeserializeOwned>(&self, operation: Operation) -> Result<T, Error> {
        self.execute(operation).await?.json()
    }

    /// Sends an operation whose answer carries no body worth reading.
    pub async fn send_unit(&self, operation: Operation) -> Result<(), Error> {
        self.execute(operation).await.map(|_| ())
    }

    /// Sends a paginated read and keeps the cursor Fizzy answered with.
    pub async fn send_page<T: DeserializeOwned>(
        &self,
        operation: Operation,
    ) -> Result<Page<T>, Error> {
        let info = operation.info.clone();
        let retry = Some(self.policy_for(&operation));
        let response = self.execute(operation).await?;
        Ok(Page::new(response.json()?, &response, info, retry))
    }

    /// Sends an operation: asks the hooks whether it may run, applies credentials, retries
    /// transient failures under the operation's policy, and answers a cached body on 304.
    /// Non-2xx statuses become errors.
    pub async fn execute(&self, operation: Operation) -> Result<Response, Error> {
        let work = self.dispatch(&operation);
        #[cfg(feature = "tracing")]
        let work = {
            use tracing::Instrument;
            let span = tracing::info_span!(
                "fizzy.operation",
                operation = %operation.info.operation,
                service = %operation.info.service,
                http.status = tracing::field::Empty,
                request_id = tracing::field::Empty,
            );
            async move {
                let outcome = work.await;
                let span = tracing::Span::current();
                match &outcome {
                    Ok(response) => {
                        span.record("http.status", response.status.as_u16());
                        if let Some(id) = response.header("x-request-id") {
                            span.record("request_id", id);
                        }
                    }
                    Err(error) => {
                        if let Some(status) = error.http_status() {
                            span.record("http.status", status);
                        }
                        if let Some(id) = error.request_id() {
                            span.record("request_id", id);
                        }
                    }
                }
                outcome
            }
            .instrument(span)
        };
        self.instrument(&operation, work).await
    }

    /// Runs one operation inside the hook lifecycle every call shares.
    ///
    /// The end is reported from a drop guard rather than after the await, because the await
    /// may never return: a caller's `tokio::time::timeout` or `select!` can drop the future
    /// mid-flight, and a start with no end leaves the bulkhead a permit short and the
    /// circuit breaker a call short for the life of the client. Dropped that way, the
    /// operation ends as [`Error::cancelled`].
    async fn instrument<T>(
        &self,
        operation: &Operation,
        work: impl Future<Output = Result<T, Error>>,
    ) -> Result<T, Error> {
        let hooks = &self.shared.hooks;
        hooks.on_operation_gate(&operation.info).await?;

        let mut running = Running {
            hooks,
            info: &operation.info,
            state: Some(hooks.on_operation_start(&operation.info)),
            started: Instant::now(),
        };
        let outcome = work.await;
        running.finished(outcome.as_ref().map(|_| ()));
        outcome
    }

    /// Reads the answer the retry loop settled on, and tells the hooks how it turned out
    /// once its body has been dealt with.
    async fn dispatch(&self, operation: &Operation) -> Result<Response, Error> {
        let url = self.url_for(operation)?;
        let answered = self.attempt(operation, &url).await?;
        let status = answered.status;
        let finished = self
            .finish(
                operation,
                &url,
                answered.url,
                status,
                answered.headers,
                answered.body,
                answered.cached,
            )
            .await;
        self.shared.hooks.on_request_end(
            &answered.info,
            &RequestResult {
                status: Some(status),
                duration: answered.duration,
                error: finished.as_ref().err(),
                from_cache: finished.as_ref().is_ok_and(|response| response.from_cache),
                retryable: answered.retryable,
                retry_after: answered.retry_after,
            },
        );
        finished
    }

    /// The policy an operation is sent under: its own, or the client's defaults for a raw
    /// call, and in either case no more attempts and no longer a first wait than the
    /// client allows. A call that is not idempotent is sent once whatever else says.
    pub(crate) fn policy_for(&self, operation: &Operation) -> RetryPolicy {
        let shared = &self.shared;
        if !operation.idempotent {
            return RetryPolicy::none();
        }
        let policy = operation.retry.clone().unwrap_or_else(|| RetryPolicy {
            attempts: shared.max_attempts,
            base_delay: shared.base_delay,
            retry_on: Cow::Borrowed(DEFAULT_RETRY_ON),
        });
        RetryPolicy {
            attempts: policy.attempts.min(shared.max_attempts).max(1),
            base_delay: policy.base_delay.min(shared.max_delay),
            retry_on: policy.retry_on,
        }
    }

    /// Sends the operation as many times as its retry budget and Fizzy's answers call for,
    /// and hands back the answer it stopped on with the body still unread.
    async fn attempt(&self, operation: &Operation, url: &Url) -> Result<Answered, Error> {
        let policy = self.policy_for(operation);
        let mut backoff = Backoff {
            attempt: 1,
            delay: policy.base_delay,
        };
        // Looked up once and carried across the attempts: a resend would find the same
        // entry, and the cache the SDK ships reads it off disk.
        let mut cached = None;

        loop {
            let once = self.attempt_once(operation, url, &policy, &mut backoff, &mut cached);
            if let Some(answered) = once.await? {
                return Ok(answered);
            }
        }
    }

    /// One request, and what came of it: the answer the loop settles on, or `None` once
    /// the wait before the next attempt is over.
    async fn attempt_once(
        &self,
        operation: &Operation,
        url: &Url,
        policy: &RetryPolicy,
        backoff: &mut Backoff,
        cached: &mut Option<(String, CachedResponse)>,
    ) -> Result<Option<Answered>, Error> {
        let hooks = &self.shared.hooks;
        let attempt = backoff.attempt;
        let request = self.prepare(operation, url, cached).await?;
        let info = RequestInfo {
            method: operation.method.clone(),
            url: url.clone(),
            attempt,
        };
        hooks.on_request_start(&info);
        let started = Instant::now();
        let sent = self.transmit(operation, url.clone(), request).await;
        let duration = started.elapsed();

        let (final_url, response) = match sent {
            Err(error) => {
                let again = error.is_retryable() && attempt < policy.attempts;
                hooks.on_request_end(
                    &info,
                    &RequestResult::failed(None, duration, &error, error.is_retryable(), None),
                );
                return if again {
                    self.resend(backoff, &info, operation, &error, None, "request failed")
                        .await;
                    Ok(None)
                } else {
                    Err(error)
                };
            }
            Ok(sent) => sent,
        };

        let status = response.status();
        let retryable = policy.retry_on.contains(&status.as_u16());
        let retry_after = retry_after_asked(status, response.headers());
        let wait = match retry_after {
            Some(seconds) if seconds > 0 => Some(Duration::from_secs(seconds)),
            _ => None,
        };
        let too_long = wait.is_some_and(|wait| wait > self.shared.max_retry_after);
        if retryable && attempt < policy.attempts && !too_long {
            let cause = Error::from_response(status, &operation.method, response.headers(), &[]);
            hooks.on_request_end(
                &info,
                &RequestResult::failed(Some(status), duration, &cause, retryable, retry_after),
            );
            self.resend(backoff, &info, operation, &cause, wait, "retryable status")
                .await;
            return Ok(None);
        }

        let (parts, body) = response.into_parts();
        match self.read_answer(operation, url, status, body).await {
            Ok(body) => Ok(Some(Answered {
                url: final_url,
                status,
                headers: parts.headers,
                body,
                cached: cached.take(),
                info,
                duration,
                retryable,
                retry_after,
            })),
            Err(error) => {
                let mut again = attempt < policy.attempts;
                let error = unread(operation, status, &parts.headers, error, &mut again);
                hooks.on_request_end(
                    &info,
                    &RequestResult::failed(Some(status), duration, &error, again, None),
                );
                if again {
                    self.resend(backoff, &info, operation, &error, None, "body broke off")
                        .await;
                    Ok(None)
                } else {
                    Err(error)
                }
            }
        }
    }

    /// Tells the hooks a resend is coming, waits it out — `wait` when Fizzy named one,
    /// the backoff otherwise — and moves the loop on to the next attempt.
    async fn resend(
        &self,
        backoff: &mut Backoff,
        info: &RequestInfo,
        operation: &Operation,
        error: &Error,
        wait: Option<Duration>,
        why: &str,
    ) {
        crate::trace::debug(&operation.id, backoff.attempt, &format!("{why}, retrying"));
        self.shared.hooks.on_retry(info, backoff.attempt + 1, error);
        self.wait(wait.unwrap_or(backoff.delay)).await;
        backoff.delay = self.next_delay(backoff.delay);
        backoff.attempt += 1;
    }

    /// Reads the body of the answer an attempt settled on: whole, up to the cap, for a
    /// success; no more than the diagnostic prefix a failure keeps, for anything else.
    async fn read_answer(
        &self,
        operation: &Operation,
        url: &Url,
        status: StatusCode,
        body: Body,
    ) -> Result<Bytes, Error> {
        if status.is_success() {
            let bound = self.shared.max_response_body_bytes;
            read_body(body, bound, &operation.method, url.path()).await
        } else {
            body.prefix(MAX_ERROR_BODY_BYTES).await
        }
    }

    /// Where an operation goes. Whatever the path was — relative, absolute, pasted — the
    /// resolved URL has to sit on the Fizzy origin the client was built for: every request
    /// carries the credentials, and this is the one place all of them pass through.
    pub(crate) fn url_for(&self, operation: &Operation) -> Result<Url, Error> {
        let mut url = match &operation.url {
            Some(url) => url.clone(),
            None => self
                .shared
                .base_url
                .join(operation.path.trim_start_matches('/'))?,
        };
        if !operation.query.is_empty() {
            url.query_pairs_mut().extend_pairs(&operation.query);
        }
        require_secure_endpoint(&url)?;
        if !url.username().is_empty() || url.password().is_some() {
            return Err(Error::usage(format!(
                "{} names a URL carrying credentials; use an access token or a session token",
                operation.id
            )));
        }
        if !is_same_origin(&url, &self.shared.base_url) {
            return Err(Error::usage(format!(
                "{} resolves off the Fizzy origin {}, onto {}",
                operation.id,
                self.shared.base_url.origin().ascii_serialization(),
                url.origin().ascii_serialization()
            )));
        }
        Ok(url)
    }

    /// Builds the request for one attempt, and looks the response cache up the first time
    /// it is asked for a key. `cached` carries the entry — or the empty stand-in that says
    /// "cacheable, nothing stored" — from one attempt to the next.
    async fn prepare(
        &self,
        operation: &Operation,
        url: &Url,
        cached: &mut Option<(String, CachedResponse)>,
    ) -> Result<Request<Bytes>, Error> {
        let mut request = Request::builder()
            .method(operation.method.clone())
            .uri(url.as_str())
            .body(Bytes::new())
            .map_err(Error::from_std)?;
        let headers = request.headers_mut();
        headers.insert(USER_AGENT, header_value(&self.shared.user_agent)?);
        headers.insert(ACCEPT, HeaderValue::from_static("application/json"));
        for (name, value) in &operation.headers {
            headers.append(name.clone(), value.clone());
        }
        if let Some(body) = &operation.body {
            headers.insert(CONTENT_TYPE, header_value(&body.content_type)?);
            *request.body_mut() = body.bytes.clone();
        }
        self.shared.auth.authenticate(&mut request).await?;

        let key = match self.cacheable(operation) {
            None => None,
            Some(cache) => match credential(request.headers()) {
                None => None,
                Some(credential) => {
                    let key = cache_key(url.as_str(), &credential);
                    if cached.as_ref().is_none_or(|(held, _)| *held != key) {
                        *cached = self.look_up(cache, &key).await;
                    }
                    Some(key)
                }
            },
        };
        if key.is_none() {
            *cached = None;
        }
        if let Some((_, entry)) = cached.as_ref()
            && !entry.etag.is_empty()
        {
            let validator = header_value(&entry.etag)?;
            request.headers_mut().insert(IF_NONE_MATCH, validator);
        }
        Ok(request)
    }

    /// What the cache holds for a key, as the attempt should carry it: the stored entry, an
    /// empty stand-in when there is nothing stored, and nothing at all when what is stored
    /// is longer than the client would hold — which is thrown away on the way past.
    async fn look_up(
        &self,
        cache: &Arc<dyn ResponseCache>,
        key: &str,
    ) -> Option<(String, CachedResponse)> {
        match cache_get(cache, key).await {
            Some(entry) if entry.body.len() <= self.shared.max_response_body_bytes => {
                Some((key.to_string(), entry))
            }
            Some(_) => {
                cache_invalidate(cache, key).await;
                None
            }
            None => Some((
                key.to_string(),
                CachedResponse {
                    etag: String::new(),
                    body: Bytes::new(),
                },
            )),
        }
    }

    /// The cache the operation reads and writes, when there is one to use. Cached bodies
    /// are held per identity, so a request that goes out without credentials is not
    /// cached: there would be nothing to tell one caller's copy from another's.
    fn cacheable(&self, operation: &Operation) -> Option<&Arc<dyn ResponseCache>> {
        if operation.no_cache || operation.method != Method::GET {
            None
        } else {
            self.shared.cache.as_ref()
        }
    }

    /// Sends one request and follows the redirects it is answered with, up to
    /// [`MAX_REDIRECTS`] hops, as long as they stay on the Fizzy origin. Hands back the
    /// URL the answer came from along with the answer.
    ///
    /// A hop off the origin is refused rather than followed: Fizzy's API never sends one,
    /// and following it would carry the credentials — the ones the client puts on, and any
    /// the transport adds of its own — somewhere they were never meant to go. A 301, 302
    /// or 303 turns anything but a GET or HEAD into a GET without its body; a 307 or 308
    /// keeps both.
    async fn transmit(
        &self,
        operation: &Operation,
        mut url: Url,
        mut request: Request<Bytes>,
    ) -> Result<(Url, HttpResponse<Body>), Error> {
        let mut hops = 0;
        loop {
            let outgoing = (
                request.method().clone(),
                request.headers().clone(),
                request.body().clone(),
            );
            let response = self.shared.http.send(request).await?;
            match redirect_target(&url, &response) {
                None => return Ok((url, response)),
                Some(_) if hops == MAX_REDIRECTS => {
                    return Err(Error::new(
                        ErrorCode::Network,
                        format!(
                            "{} redirected more than {MAX_REDIRECTS} times",
                            operation.id
                        ),
                    )
                    .retryable());
                }
                Some(next) => {
                    require_secure_endpoint(&next)?;
                    if !next.username().is_empty() || next.password().is_some() {
                        return Err(Error::usage(format!(
                            "{} redirected to a URL carrying credentials",
                            operation.id
                        )));
                    }
                    if !is_same_origin(&next, &self.shared.base_url) {
                        return Err(Error::usage(format!(
                            "{} redirected off the Fizzy origin to {}",
                            operation.id,
                            next.origin().ascii_serialization()
                        )));
                    }
                    request = redirected(outgoing, response.status(), &next)?;
                    url = next;
                    hops += 1;
                }
            }
        }
    }

    #[allow(clippy::too_many_arguments)]
    async fn finish(
        &self,
        operation: &Operation,
        url: &Url,
        final_url: Url,
        status: StatusCode,
        headers: HeaderMap,
        body: Bytes,
        cached: Option<(String, CachedResponse)>,
    ) -> Result<Response, Error> {
        // An answer that arrived from somewhere other than where the request went is not
        // the document the cache holds under the request's key, and is not stored there.
        let cached = if final_url == *url { cached } else { None };

        if status == StatusCode::NOT_MODIFIED {
            return match cached {
                Some((_, entry)) if !entry.etag.is_empty() => Ok(Response {
                    status: StatusCode::OK,
                    headers,
                    body: entry.body,
                    url: final_url,
                    from_cache: true,
                }),
                _ => Err(Error::api(
                    304,
                    "304 received but no cached response available",
                )),
            };
        }

        if status.is_success() {
            if let (Some((key, _)), Some(cache)) = (cached, self.cacheable(operation))
                && let Some(etag) = headers.get("etag").and_then(|value| value.to_str().ok())
            {
                cache_set(
                    cache,
                    &key,
                    CachedResponse {
                        etag: etag.to_string(),
                        body: body.clone(),
                    },
                )
                .await;
            }
            Ok(Response {
                status,
                headers,
                body,
                url: final_url,
                from_cache: false,
            })
        } else {
            Err(Error::from_response(
                status,
                &operation.method,
                &headers,
                &body,
            ))
        }
    }

    async fn wait(&self, delay: Duration) {
        let jitter = match u64::try_from(self.shared.max_jitter.as_millis()).unwrap_or(u64::MAX) {
            0 => Duration::ZERO,
            millis => Duration::from_millis(rand::random_range(0..millis)),
        };
        tokio::time::sleep(delay + jitter).await;
    }

    fn next_delay(&self, delay: Duration) -> Duration {
        (delay * 2).min(self.shared.max_delay)
    }
}

/// An operation the hooks have been told the start of and are still owed the end of. It
/// reports the end whichever way the operation leaves: [`Running::finished`] with the
/// outcome, or the drop that comes instead when the caller abandons the future.
struct Running<'a> {
    hooks: &'a Arc<dyn Hooks>,
    info: &'a OperationInfo,
    state: Option<OperationState>,
    started: Instant,
}

impl Running<'_> {
    fn finished(&mut self, outcome: Result<(), &Error>) {
        if let Some(state) = self.state.take() {
            self.hooks
                .on_operation_end(self.info, state, outcome, self.started.elapsed());
        }
    }
}

impl Drop for Running<'_> {
    fn drop(&mut self) {
        if self.state.is_some() {
            self.finished(Err(&Error::cancelled()));
        }
    }
}

/// One answer from Fizzy, body read: what the retry loop settled on, the URL it came from
/// once any redirects were followed, and what the hooks still have to be told about it
/// once the body has been dealt with.
struct Answered {
    url: Url,
    status: StatusCode,
    headers: HeaderMap,
    body: Bytes,
    cached: Option<(String, CachedResponse)>,
    info: RequestInfo,
    duration: Duration,
    retryable: bool,
    retry_after: Option<u64>,
}

/// The credential a request carries, for keying the cache: the bearer token or the cookie.
fn credential(headers: &HeaderMap) -> Option<String> {
    headers
        .get(AUTHORIZATION)
        .or_else(|| headers.get(COOKIE))
        .and_then(|value| value.to_str().ok())
        .map(str::to_string)
}

/// The cache is whatever the caller supplied, and the one the SDK ships keeps its entries in
/// files. So every read and write of it goes to the blocking pool: a file read on the
/// runtime's own thread stalls every other task sharing that thread. A cache that cannot be
/// reached is a miss, which is what any other failure to read it is too.
async fn cache_get(cache: &Arc<dyn ResponseCache>, key: &str) -> Option<CachedResponse> {
    let cache = cache.clone();
    let key = key.to_string();
    tokio::task::spawn_blocking(move || cache.get(&key))
        .await
        .ok()
        .flatten()
}

async fn cache_set(cache: &Arc<dyn ResponseCache>, key: &str, response: CachedResponse) {
    let cache = cache.clone();
    let key = key.to_string();
    let _ = tokio::task::spawn_blocking(move || cache.set(&key, response)).await;
}

async fn cache_invalidate(cache: &Arc<dyn ResponseCache>, key: &str) {
    let cache = cache.clone();
    let key = key.to_string();
    let _ = tokio::task::spawn_blocking(move || cache.invalidate(&key)).await;
}

#[cfg(feature = "reqwest")]
fn shipped_http_client(timeout: Duration) -> Result<Arc<dyn HttpClient>, Error> {
    Ok(Arc::new(crate::http::ReqwestClient::with_timeout(timeout)?))
}

#[cfg(not(feature = "reqwest"))]
fn shipped_http_client(_timeout: Duration) -> Result<Arc<dyn HttpClient>, Error> {
    Err(Error::usage(
        "no HTTP client: supply one with ClientBuilder::http_client, or enable the reqwest feature",
    ))
}

/// Where a redirect points, when the answer is one and says where. A 3xx without a
/// `Location`, or with one that is not a URL, is handed back as the answer it is.
fn redirect_target(url: &Url, response: &HttpResponse<Body>) -> Option<Url> {
    let status = response.status();
    if status.is_redirection() && status != StatusCode::NOT_MODIFIED {
        response
            .headers()
            .get("location")
            .and_then(|value| value.to_str().ok())
            .and_then(|location| url.join(location).ok())
    } else {
        None
    }
}

/// The request to send to `next`: the same one, reduced to a GET when the status asks for
/// it, and without the cache validator, which belonged to the URL the request left.
fn redirected(
    (method, mut headers, body): (Method, HeaderMap, Bytes),
    status: StatusCode,
    next: &Url,
) -> Result<Request<Bytes>, Error> {
    headers.remove(IF_NONE_MATCH);
    let keeps_method = method == Method::GET
        || method == Method::HEAD
        || status == StatusCode::TEMPORARY_REDIRECT
        || status == StatusCode::PERMANENT_REDIRECT;
    let (method, body) = if keeps_method {
        (method, body)
    } else {
        headers.remove(CONTENT_TYPE);
        headers.remove(CONTENT_LENGTH);
        (Method::GET, Bytes::new())
    };
    let mut request = Request::builder()
        .method(method)
        .uri(next.as_str())
        .body(body)
        .map_err(Error::from_std)?;
    *request.headers_mut() = headers;
    Ok(request)
}

fn parse_base_url(base_url: &str) -> Result<Url, Error> {
    let mut url = Url::parse(base_url)
        .map_err(|error| Error::usage(format!("base URL {base_url}: {error}")))?;
    require_secure_endpoint(&url)?;
    if !url.username().is_empty() || url.password().is_some() {
        return Err(Error::usage(
            "base URL must not carry credentials; use an access token or a session token",
        ));
    }
    if !url.path().ends_with('/') {
        url.set_path(&format!("{}/", url.path()));
    }
    Ok(url)
}

/// The wait Fizzy asked for, on the two statuses that carry one.
fn retry_after_asked(status: StatusCode, headers: &HeaderMap) -> Option<u64> {
    if status == StatusCode::TOO_MANY_REQUESTS || status == StatusCode::SERVICE_UNAVAILABLE {
        retry_after_seconds(headers)
    } else {
        None
    }
}

fn header_value(value: &str) -> Result<HeaderValue, Error> {
    HeaderValue::from_str(value)
        .map_err(|_| Error::usage(format!("{value:?} is not a valid header value")))
}

/// Reads a body up to the bound and refuses it on the first byte past. A body exactly at
/// the bound reads whole; one declared past it never starts.
/// The error for a body that could not be read, and whether the answer is asked for
/// again: a success whose body broke off is, while the budget allows; a refusal is not,
/// and a failure keeps its status over the reason its body was lost.
fn unread(
    operation: &Operation,
    status: StatusCode,
    headers: &HeaderMap,
    error: Error,
    again: &mut bool,
) -> Error {
    *again = *again && status.is_success() && error.is_retryable();
    if status.is_success() {
        error
    } else {
        Error::from_response(status, &operation.method, headers, &[]).refusing(error)
    }
}

/// Where the retry loop stands: which attempt is next, and how long the wait before it is.
struct Backoff {
    attempt: u32,
    delay: Duration,
}

pub(crate) async fn read_body(
    body: Body,
    limit: usize,
    method: &Method,
    path: &str,
) -> Result<Bytes, Error> {
    body.collect(limit, || Error::response_too_large(limit, method, path))
        .await
}

#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests {
    use std::sync::Mutex;

    use async_trait::async_trait;
    use serde_json::Value;

    use super::*;
    use crate::auth::StaticTokenProvider;

    /// An [`HttpClient`] with no network behind it: it answers each request from a closure
    /// and keeps what it was sent. This is the second implementation the trait exists for,
    /// so the client is exercised here with no `reqwest` in the picture.
    struct Canned {
        answer: Box<Answer>,
        sent: Mutex<Vec<(Method, String, HeaderMap)>>,
    }

    type Answer = dyn Fn(&Request<Bytes>) -> HttpResponse<Body> + Send + Sync;

    impl Canned {
        fn new(
            answer: impl Fn(&Request<Bytes>) -> HttpResponse<Body> + Send + Sync + 'static,
        ) -> Arc<Canned> {
            Arc::new(Canned {
                answer: Box::new(answer),
                sent: Mutex::new(Vec::new()),
            })
        }

        fn sent(&self) -> Vec<(Method, String, HeaderMap)> {
            self.sent.lock().unwrap().clone()
        }
    }

    #[async_trait]
    impl HttpClient for Arc<Canned> {
        async fn send(&self, request: Request<Bytes>) -> Result<HttpResponse<Body>, Error> {
            self.sent.lock().unwrap().push((
                request.method().clone(),
                request.uri().to_string(),
                request.headers().clone(),
            ));
            Ok((self.answer)(&request))
        }
    }

    fn answer(status: u16, body: &'static str) -> HttpResponse<Body> {
        let mut response = HttpResponse::new(Body::from(body));
        *response.status_mut() = StatusCode::from_u16(status).unwrap();
        response
    }

    fn redirect(location: &str) -> HttpResponse<Body> {
        let mut response = answer(302, "");
        response
            .headers_mut()
            .insert("location", HeaderValue::from_str(location).unwrap());
        response
    }

    fn client_over(http: Arc<Canned>) -> Client {
        Client::builder(Config::default().with_base_url("https://fizzy.test"))
            .token_provider(StaticTokenProvider::new("secret"))
            .http_client(http)
            .max_attempts(1)
            .build()
            .unwrap()
    }

    #[tokio::test]
    async fn a_request_goes_out_on_the_supplied_http_client_with_credentials() {
        let http = Canned::new(|_| answer(200, r#"{"ok":true}"#));
        let client = client_over(http.clone());

        let body: Value = client
            .send(client.request(Method::GET, "/my/identity.json"))
            .await
            .unwrap();

        assert_eq!(body, serde_json::json!({ "ok": true }));
        let sent = http.sent();
        assert_eq!(sent.len(), 1);
        assert_eq!(sent[0].0, Method::GET);
        assert_eq!(sent[0].1, "https://fizzy.test/my/identity.json");
        assert_eq!(sent[0].2[AUTHORIZATION], "Bearer secret");
    }

    #[tokio::test]
    async fn a_redirect_on_the_same_origin_is_followed_with_credentials() {
        let http = Canned::new(|request| {
            if request.uri().path() == "/old.json" {
                redirect("/new.json")
            } else {
                answer(200, r#"{"moved":true}"#)
            }
        });
        let client = client_over(http.clone());

        let response = client
            .execute(client.request(Method::GET, "/old.json"))
            .await
            .unwrap();

        assert_eq!(response.url.as_str(), "https://fizzy.test/new.json");
        assert_eq!(response.body, r#"{"moved":true}"#);
        let sent = http.sent();
        assert_eq!(sent.len(), 2);
        assert_eq!(sent[1].2[AUTHORIZATION], "Bearer secret");
    }

    #[tokio::test]
    async fn a_redirect_off_the_origin_is_refused_with_nothing_sent_there() {
        let http = Canned::new(|_| redirect("https://storage.test/blobs/1"));
        let client = client_over(http.clone());

        let error = client.get("/blobs/1").await.unwrap_err();

        assert_eq!(error.code(), ErrorCode::Usage);
        assert_eq!(http.sent().len(), 1);
    }

    fn broken_body(status: u16) -> HttpResponse<Body> {
        let chunks = futures_util::stream::iter([
            Ok(Bytes::from_static(b"{\"ok\":")),
            Err(Error::new(ErrorCode::Network, "cut off").retryable()),
        ]);
        let mut response = HttpResponse::new(Body::from_stream(chunks, None));
        *response.status_mut() = StatusCode::from_u16(status).unwrap();
        response
    }

    #[tokio::test]
    async fn a_body_that_breaks_off_is_asked_for_again() {
        let calls = Arc::new(Mutex::new(0));
        let seen = calls.clone();
        let http = Canned::new(move |_| {
            let mut calls = seen.lock().unwrap();
            *calls += 1;
            if *calls == 1 {
                broken_body(200)
            } else {
                answer(200, r#"{"ok":true}"#)
            }
        });
        let client = Client::builder(Config::default().with_base_url("https://fizzy.test"))
            .token_provider(StaticTokenProvider::new("secret"))
            .http_client(http.clone())
            .max_attempts(2)
            .max_jitter(Duration::ZERO)
            .base_delay(Duration::from_millis(1))
            .build()
            .unwrap();

        let response = client.get("/x.json").await.unwrap();

        assert_eq!(response.body, r#"{"ok":true}"#);
        assert_eq!(http.sent().len(), 2);
    }

    #[tokio::test]
    async fn a_failure_whose_body_breaks_off_keeps_its_status_and_is_not_resent() {
        let http = Canned::new(|_| broken_body(422));
        let client = Client::builder(Config::default().with_base_url("https://fizzy.test"))
            .token_provider(StaticTokenProvider::new("secret"))
            .http_client(http.clone())
            .max_attempts(2)
            .max_jitter(Duration::ZERO)
            .base_delay(Duration::from_millis(1))
            .build()
            .unwrap();

        let error = client.get("/x.json").await.unwrap_err();

        assert_eq!(error.code(), ErrorCode::Validation);
        assert_eq!(error.http_status(), Some(422));
        assert_eq!(http.sent().len(), 1);
    }

    #[tokio::test]
    async fn a_redirect_carrying_credentials_is_refused_without_echoing_them() {
        let http = Canned::new(|_| redirect("https://user:s3cret@fizzy.test/new.json"));
        let client = client_over(http.clone());

        let error = client.get("/old.json").await.unwrap_err();

        assert_eq!(error.code(), ErrorCode::Usage);
        assert!(!error.to_string().contains("s3cret"));
        assert_eq!(http.sent().len(), 1);
    }

    #[tokio::test]
    async fn a_path_that_resolves_off_the_origin_is_refused_before_anything_is_sent() {
        let http = Canned::new(|_| answer(200, "{}"));
        let client = client_over(http.clone());

        for path in [
            "http://evil.test/x",
            "HTTP://evil.test/x",
            "https://evil.test/x",
        ] {
            let error = client.get(path).await.unwrap_err();
            assert_eq!(error.code(), ErrorCode::Usage, "{path}");
            let error = client
                .execute(client.request(Method::GET, path))
                .await
                .unwrap_err();
            assert_eq!(error.code(), ErrorCode::Usage, "{path}");
        }
        assert!(http.sent().is_empty());
    }

    #[tokio::test]
    async fn a_url_carrying_userinfo_is_refused_without_echoing_it() {
        let http = Canned::new(|_| answer(200, "{}"));
        let client = client_over(http.clone());

        let error = client
            .get("https://user:s3cret@fizzy.test/x")
            .await
            .unwrap_err();

        assert_eq!(error.code(), ErrorCode::Usage);
        assert!(!error.to_string().contains("s3cret"));
        assert!(http.sent().is_empty());
    }

    #[tokio::test]
    async fn a_refused_redirect_is_not_retried() {
        let http = Canned::new(|_| redirect("http://evil.test/"));
        let client = Client::builder(Config::default().with_base_url("https://fizzy.test"))
            .token_provider(StaticTokenProvider::new("secret"))
            .http_client(http.clone())
            .max_jitter(Duration::ZERO)
            .base_delay(Duration::from_millis(1))
            .build()
            .unwrap();

        let error = client.get("/anything").await.unwrap_err();

        assert_eq!(error.code(), ErrorCode::Usage);
        assert_eq!(http.sent().len(), 1);
    }

    #[test]
    fn a_response_and_an_operation_print_without_their_secrets() {
        let mut headers = HeaderMap::new();
        headers.insert(
            "set-cookie",
            HeaderValue::from_static("session_token=s3cret; HttpOnly"),
        );
        let response = Response {
            status: StatusCode::OK,
            headers,
            body: Bytes::from_static(br#"{"email_address":"jane@example.com"}"#),
            url: Url::parse("https://fizzy.test/x").unwrap(),
            from_cache: false,
        };
        let printed = format!("{response:?}");
        assert!(!printed.contains("s3cret"));
        assert!(!printed.contains("jane@example.com"));
        assert!(printed.contains("[REDACTED]"));

        let mut operation = Operation::raw(Method::POST, "/session.json".into());
        operation
            .json(&serde_json::json!({"email_address": "jane@example.com"}))
            .unwrap();
        let printed = format!("{operation:?}");
        assert!(!printed.contains("jane@example.com"));
        assert!(printed.contains("len"));
    }

    #[tokio::test]
    async fn a_redirect_to_plain_http_elsewhere_is_refused() {
        let http = Canned::new(|_| redirect("http://evil.test/"));
        let client = client_over(http.clone());

        let error = client.get("/anything").await.unwrap_err();

        assert_eq!(error.code(), ErrorCode::Usage);
        assert_eq!(http.sent().len(), 1);
    }

    #[tokio::test]
    async fn a_redirect_loop_is_given_up_on() {
        let http = Canned::new(|_| redirect("/again"));
        let client = client_over(http.clone());

        let error = client.get("/again").await.unwrap_err();

        assert_eq!(error.code(), ErrorCode::Network);
        assert_eq!(http.sent().len(), MAX_REDIRECTS + 1);
    }

    #[test]
    fn base_url_must_be_https_or_local() {
        assert!(parse_base_url("https://fizzy.do").is_ok());
        assert!(parse_base_url("http://127.0.0.1:3000").is_ok());
        assert_eq!(
            parse_base_url("http://evil.example.com")
                .unwrap_err()
                .code(),
            ErrorCode::Usage
        );
        assert_eq!(
            parse_base_url("https://user:secret@fizzy.do")
                .unwrap_err()
                .code(),
            ErrorCode::Usage
        );
    }

    #[test]
    fn an_account_id_has_to_fit_in_a_path() {
        let http = Canned::new(|_| answer(200, "[]"));
        let client = client_over(http);
        assert!(client.for_account("999").is_ok());
        assert!(client.for_account("").is_err());
        assert!(client.for_account("a/b").is_err());
    }
}
