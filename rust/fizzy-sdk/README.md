# Fizzy Rust SDK

The Rust client for the [Fizzy](https://fizzy.do) API. Types, routes and service methods are
generated from the Smithy model in the repository's `spec/` directory, so what the crate offers
is what Fizzy serves. Everything else — authentication, retries, pagination, the response cache,
hooks — is the plumbing they share.

[crates.io](https://crates.io/crates/fizzy-sdk) · [docs.rs](https://docs.rs/fizzy-sdk) ·
[repository](https://github.com/basecamp/fizzy-sdk)

## Install

```sh
cargo add fizzy-sdk tokio --features tokio/macros,tokio/rt-multi-thread
```

The client is async on Tokio, with `rustls` for TLS and no OpenSSL link. Requires Rust 1.88 or
newer.

| Feature   | Default | What it adds                                                          |
|-----------|---------|-----------------------------------------------------------------------|
| `reqwest` | yes     | The shipped HTTP client. Off, supply your own `HttpClient`.           |
| `rustls`  | yes     | TLS for the shipped client. The only backend; there is no native-tls. |
| `tracing` | yes     | One `tracing` span per operation, carrying the status and request id.   |

## Authenticate

Fizzy speaks two credentials and no OAuth. A bearer token, for scripts, CLIs and anything that
already holds one:

```rust,no_run
use fizzy_sdk::{Client, Config, StaticTokenProvider};

# fn main() -> Result<(), fizzy_sdk::Error> {
let token = std::env::var("FIZZY_TOKEN").unwrap_or_default();
let client = Client::new(Config::default().with_env(), StaticTokenProvider::new(token))?;
# Ok(())
# }
```

A session token, for the mobile and web shells that signed in with a magic link:

```rust,no_run
use fizzy_sdk::{Client, Config};

# fn main() -> Result<(), fizzy_sdk::Error> {
let client = Client::builder(Config::default())
    .session_token(std::env::var("FIZZY_SESSION").unwrap_or_default())
    .build()?;
# Ok(())
# }
```

And the magic-link flow that produces one. `create_session` asks Fizzy to email a code and keeps
the pending token the answer carries; `redeem` sends the code back with it. A process that
finishes the flow later resumes it with `MagicLinkFlow::resume` and the pending token.

```rust,no_run
use fizzy_sdk::{Client, Config, MagicLinkFlow};

# async fn run(email: &str, code: &str) -> Result<(), fizzy_sdk::Error> {
let flow = MagicLinkFlow::new(Config::default())?;
flow.create_session(email).await?;
// ...the person reads the code out of the email...
let session = flow.redeem(code).await?;
let client = Client::builder(Config::default())
    .session_token(session.session_token)
    .build()?;
# Ok(())
# }
```

`Config::with_env` reads `FIZZY_API_URL`, `FIZZY_ACCOUNT`, `FIZZY_CACHE_DIR` and
`FIZZY_CACHE_ENABLED`, the same variables the Go SDK reads. The token itself is the
application's to keep: implement `TokenProvider` over your own store, or `AuthStrategy` to set
the headers outright.

## Use it

Most of Fizzy lives under an account. `for_account` scopes a client to one; the handful of
routes outside an account — sessions, identity, access tokens, signup — hang off the client
itself.

```rust,no_run
use fizzy_sdk::models::{CreateBoardRequestContent, CreateCardRequestContent};
use fizzy_sdk::{Client, Config, StaticTokenProvider};

# async fn run() -> Result<(), fizzy_sdk::Error> {
let client = Client::new(Config::default(), StaticTokenProvider::new("tok_..."))?;
let account = client.for_account("999")?;

let boards = account.boards().list().await?;   // a Page: derefs to the Vec it wraps
for board in boards.iter() {
    println!("{} ({})", board.name, board.id);
}

let board = account.boards().create(&CreateBoardRequestContent {
    name: "Launch".into(),
    ..Default::default()
}).await?;

account.cards().create(&CreateCardRequestContent {
    board_id: Some(board.id.clone()),
    title: "Write the announcement".into(),
    ..Default::default()
}).await?;

let me = client.identity().get_my_identity().await?;
# Ok(())
# }
```

### Services

One handle per resource: `access_tokens`, `identity`, `sessions` on the client; `account`,
`boards`, `cards`, `columns`, `comments`, `devices`, `identity`, `notifications`, `pins`,
`reactions`, `search`, `steps`, `tags`, `uploads`, `users`, `webhooks` on the account.

Every operation the model describes is generated, named for the operation with the service's
noun dropped: `ListBoards` is `boards().list()`, `ListClosedCards` is
`boards().list_closed(board_id)`, `MarkCardRead` is `cards().mark_read(card_number)`. Operation
ids, methods, paths, retry policies and pagination styles are all public data in
`fizzy_sdk::routes`; naming overrides live in `rust/generator/names.toml`.

Request bodies are plain structs that derive `Default`, built with `..Default::default()`.
Responses are `#[non_exhaustive]`: a field Fizzy adds later is not a breaking change.

### Pages and streams

A list operation answers a `Page<T>`: the decoded body, plus the `Link` header Fizzy sent.
Walk pages one at a time, or as a `Stream` of pages or items that reads lazily as it is polled.

```rust,no_run
use fizzy_sdk::{Client, Config, StaticTokenProvider};
use futures_util::TryStreamExt;

# async fn run() -> Result<(), fizzy_sdk::Error> {
let client = Client::new(Config::default(), StaticTokenProvider::new("tok_..."))?;
let account = client.for_account("999")?;

let first = account.boards().list().await?;
if let Some(second) = client.next_page(&first).await? {
    println!("{} more boards", second.len());
}

let mut cards = std::pin::pin!(client.items(account.boards().list_closed("b1").await?));
while let Some(card) = cards.try_next().await? {
    println!("{}", card.title);
}
# Ok(())
# }
```

A `Link` pointing off the configured origin is refused as a usage error rather than followed,
and a walk stops at the client's page limit (10,000 by default). For a path the model does not
cover, `get_all` reads every page as raw JSON.

## Errors

Every call answers `Result<_, fizzy_sdk::Error>`. An error carries a code, a message, a hint
when the server gave one, the HTTP status, the `X-Request-Id`, and whether a resend could have
helped.

```rust,no_run
use fizzy_sdk::{Client, Config, ErrorCode, StaticTokenProvider};

# async fn run() -> Result<(), fizzy_sdk::Error> {
let client = Client::new(Config::default(), StaticTokenProvider::new("tok_..."))?;
match client.for_account("999")?.boards().get("nope").await {
    Ok(board) => println!("{}", board.name),
    Err(error) if error.code() == ErrorCode::NotFound => println!("no such board"),
    Err(error) => {
        eprintln!("{error} (status {:?}, request {:?})", error.http_status(), error.request_id());
        std::process::exit(error.exit_code());
    }
}
# Ok(())
# }
```

Codes: `usage`, `not_found`, `auth_required`, `forbidden`, `rate_limit`, `network`, `api_error`,
`validation`, `ambiguous` — the same set, and the same CLI exit codes, as every other Fizzy SDK.
A 401 is terminal: Fizzy has no refresh token to try.

## Retries

Each operation carries its own retry policy from the model — how many attempts in total, the
base delay, which statuses to resend on — and the client follows it on the first request and on
every page after. `Retry-After` is honored, in seconds or as an HTTP date, up to
`max_retry_after`. A `POST` is never resent unless the model marks the operation idempotent; a
raw call can say so with `RequestOptions::idempotent`, or opt out with
`RequestOptions::no_retry`. Retries back off exponentially with jitter. On the builder,
`max_attempts` is a ceiling over every route's budget (3 by default, counting the first
request), `max_delay` caps a route's backoff, `max_jitter` bounds the randomness, and
`base_delay` is the first backoff for raw calls, which have no route to read one from.

## Hooks and tracing

`Hooks` is told when an operation starts and ends, when each request goes out and what it
answered, and before each resend; `on_operation_gate` may refuse a call before it is sent.
Whatever a hook sees is redacted: `Authorization` and `Cookie` never appear in a hook, a log
line or an error. `NoopHooks` does nothing and `ChainHooks` runs several in order.

```rust,no_run
use fizzy_sdk::observability::{Hooks, RequestInfo, RequestResult};
use fizzy_sdk::{Client, Config};

struct LogStatuses;

impl Hooks for LogStatuses {
    fn on_request_end(&self, info: &RequestInfo, result: &RequestResult<'_>) {
        println!("{} {} -> {:?} in {:?}", info.method, info.url, result.status, result.duration);
    }
}

# fn main() -> Result<(), fizzy_sdk::Error> {
let client = Client::builder(Config::default())
    .access_token("tok_...")
    .hooks(LogStatuses)
    .build()?;
# Ok(())
# }
```

With the `tracing` feature (on by default) every operation runs inside a span named for it,
carrying the service, the operation, and the HTTP status and request id as they are known;
each resend is a debug event on that span with the attempt number. Subscribe with any
`tracing` subscriber; the SDK depends on none.

## Caching

Reads can be cached by `ETag`: a repeat request sends `If-None-Match`, and a 304 answers from
the cache without a body on the wire. `Config::with_cache_enabled(true)` turns it on with the
file cache in `FIZZY_CACHE_DIR`; `ClientBuilder::cache` takes any `ResponseCache`, and
`fizzy_sdk::cache::InMemoryCache` is one.

## Bring your own HTTP client

Everything the SDK sends goes through one `HttpClient`. The shipped one wraps `reqwest`; a shell
that already has an HTTP stack implements the trait — one method, `send`, over the `http`
crate's request and response types, with a streaming body — and hands it to
`ClientBuilder::http_client`. Build with `--no-default-features` to leave `reqwest` out
entirely. An implementation must not follow redirects: the SDK does that itself so credentials
stay on the Fizzy origin.

## Resilience

A circuit breaker, a bulkhead and a rate limiter are available in `fizzy_sdk::resilience`,
configured through `ResilienceConfig` and installed as hooks. All three are off unless asked
for. Response bodies are capped at 10 MB and error bodies at 10 KB, so a misbehaving server
cannot exhaust memory.

## Webhooks

Fizzy signs each delivery with HMAC-SHA256 over the raw body, hex-encoded, in the header
`fizzy_sdk::webhooks::SIGNATURE_HEADER`. Verify it in constant time before trusting a payload:

```rust
use fizzy_sdk::webhooks::{compute_signature, verify_signature};

let secret = "whsec_...";
let payload = br#"{"event":"card.created"}"#;
let signature = compute_signature(payload, secret);
assert!(verify_signature(payload, &signature, secret));
assert!(!verify_signature(payload, &signature, "another secret"));
```

## Develop

From the repository root:

```sh
make rs-generate      # regenerate src/generated and tests/generated_calls from openapi.json
make rs-check         # fmt, clippy, tests, docs, cargo deny, publish dry run
make rs-check-drift   # the generator's --check over both directories, plus the operationId census
make conformance-rust # the shared conformance fixtures, through this crate
```

`rust/rust-toolchain.toml` pins the toolchain the checks are run with. Generated code is never
edited by hand; change the model in `spec/` and regenerate every language.

## Versioning

The crate follows the repository's release: every Fizzy SDK ships the same version from one tag.
Before 1.0, a breaking change bumps the minor version and an additive one the patch, and
`cargo semver-checks` runs in CI once a published baseline exists. The MSRV is 1.88 and is
raised only when a dependency or feature needs it, as a minor release with a line in the
release notes.

## License

MIT. Copyright 37signals LLC.
