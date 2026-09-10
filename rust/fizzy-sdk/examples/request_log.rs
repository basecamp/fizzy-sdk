//! Customizes the client: hooks that log every operation, attempt and resend, and the
//! retry and page bounds set by hand rather than left at their defaults. A modelled call keeps its own
//! retry policy; the builder's knobs cap it — `max_attempts` over the route's budget,
//! `max_delay` over its backoff (it is floored at `base_delay`, so both are set) — and
//! `max_jitter` zero makes the waits exact.
//!
//! ```sh
//! FIZZY_TOKEN=tok_... FIZZY_ACCOUNT=999 cargo run --example request_log
//! ```

use std::time::Duration;

use fizzy_sdk::observability::{Hooks, OperationInfo, OperationState, RequestInfo, RequestResult};
use fizzy_sdk::{Client, Config, Error};

/// Logs what the SDK does without logging where it went: a URL can carry a confirmation
/// or device token in its path, so the operation's name stands in for it.
struct RequestLog;

impl Hooks for RequestLog {
    fn on_request_end(&self, info: &RequestInfo, result: &RequestResult<'_>) {
        println!(
            "{} attempt {} -> {} in {:?}",
            info.method,
            info.attempt,
            result
                .status
                .map_or_else(|| "no answer".to_string(), |status| status.to_string()),
            result.duration
        );
    }

    fn on_retry(&self, info: &RequestInfo, next_attempt: u32, cause: &Error) {
        // The code, not the message: a transport error's message can quote the URL.
        println!(
            "resending {} as attempt {next_attempt} after {}",
            info.method,
            cause.code()
        );
    }

    fn on_operation_end(
        &self,
        op: &OperationInfo,
        _state: OperationState,
        outcome: Result<(), &Error>,
        duration: Duration,
    ) {
        match outcome {
            Ok(()) => println!("{} ok in {duration:?}", op.operation),
            Err(error) => println!("{} failed in {duration:?}: {}", op.operation, error.code()),
        }
    }
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    let client = Client::builder(Config::default().with_env())
        .access_token(std::env::var("FIZZY_TOKEN").unwrap_or_default())
        .hooks(RequestLog)
        .max_attempts(2)
        .base_delay(Duration::from_millis(250))
        .max_delay(Duration::from_millis(500))
        .max_jitter(Duration::ZERO)
        .max_pages(50)
        .build()?;

    let boards = client.for_configured_account()?.boards().list().await?;
    println!("{} board(s)", boards.len());
    Ok(())
}
