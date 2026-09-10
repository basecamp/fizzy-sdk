# Changelog

Rust-specific notes for the `fizzy-sdk` crate. Release notes for every language are on
the [GitHub releases](https://github.com/basecamp/fizzy-sdk/releases); this file carries
what a Rust consumer needs to know before upgrading.

## 0.3.0

First release of `fizzy-sdk` on crates.io. The crate is generated from the same Smithy
model as the other five SDKs and runs the shared conformance fixtures.

- Bearer and cookie authentication, and the magic-link login flow.
- Every operation in the model, generated into `services` with a public route table.
- Per-operation retry policy from the behavior model, `Retry-After` honored.
- `Link` pagination with same-origin enforcement, `Page<T>` and item streams.
- Structured `Error` with codes, hints, HTTP status and request id.
- Hooks, `tracing` spans, ETag caching, circuit breaker, bulkhead and rate limiter.
- Webhook signature verification.
- MSRV 1.88; `rustls` only.
