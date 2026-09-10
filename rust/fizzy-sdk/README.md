# fizzy-sdk

The Rust client for the [Fizzy](https://fizzy.do) API. Types, routes and service methods
are generated from the Smithy model in the repository's `spec/`; the runtime around them —
authentication, retries, pagination, hooks, the response cache — is hand-written and shared
by every call.

```sh
cargo add fizzy-sdk
```

Requires Rust 1.88 or newer and a Tokio runtime.

## Authenticating

Fizzy takes an API access token as a bearer, or a session token as a cookie. Most of the
API is scoped to an account, reached with `for_account`.

```rust,no_run
use fizzy_sdk::{Client, Config};

# async fn run() -> Result<(), fizzy_sdk::Error> {
let client = Client::builder(Config::default().with_env())
    .access_token(std::env::var("FIZZY_TOKEN").unwrap_or_default())
    .build()?;
let account = client.for_account("999")?;

for board in account.boards().list().await?.iter() {
    println!("{} ({})", board.name, board.id);
}
# Ok(())
# }
```

A session signed in through a magic link uses `.session_token(token)` instead; the
`MagicLinkFlow` in `fizzy_sdk::magic_link` runs the two steps that get one.

## What the client does for you

- **Retries** follow the behavior model per operation: attempts, backoff and the statuses
  that are resent. A POST is sent once unless the model says it is idempotent. `Retry-After`
  is honoured on 429 and 503, up to a ceiling.
- **Pagination**: a list answers a `Page`; walk on with `next_page`, `each_page`, or the
  `pages` / `items` streams. A `Link` pointing off the Fizzy origin is refused.
- **Errors** are one `Error` with a code shared by every Fizzy SDK (`auth_required`,
  `rate_limit`, `validation`, …), the HTTP status, the request id and the server's message.
- **HTTPS** is enforced for every origin but this machine; credentials are redacted from
  anything the hooks or logs see; sensitive fields are `SensitiveString`s that print as
  `[REDACTED]`.
- **Hooks** report every operation, request and retry; `ChainHooks` stacks several.
  Circuit breaker, bulkhead and rate limiter are one `resilience` config away. Reads can
  be cached by `ETag`. Webhook deliveries are verified with `fizzy_sdk::webhooks`.
- **Bring your own HTTP client** by implementing `HttpClient`; the `reqwest` feature (on by
  default) ships one.

## Developing

```sh
make rs-generate      # regenerate src/generated and tests/generated_calls from openapi.json
make rs-check         # fmt, clippy, tests, docs, cargo deny, drift, publish --dry-run
```
