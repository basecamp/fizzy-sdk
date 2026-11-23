# Changelog

Rust-specific notes for the `fizzy-sdk` crate. Release notes for every language are on
the [GitHub releases](https://github.com/basecamp/fizzy-sdk/releases); this file carries
what a Rust consumer needs to know before upgrading.

## Unreleased

- **Breaking:** dates and times are [jiff](https://docs.rs/jiff/1)'s, not chrono's.
  chrono is unmaintained ([RUSTSEC-2026-0543](https://rustsec.org/advisories/RUSTSEC-2026-0543)),
  and basecamp-sdk made the same move. `fizzy_sdk::DateTime` is `jiff::Timestamp`
  (was `chrono::DateTime<Utc>`), and `fizzy_sdk::jiff` re-exports the crate. Every
  generated `*_at` field changes type with it.
- Reading is unchanged for the timestamps Fizzy sends: RFC 3339 with any offset reads to
  the same instant. Writing is in UTC with `Z` as before, but at the shortest precision
  that keeps the value, so `.100Z` is now written `.1Z`. `Display` prints RFC 3339
  (`2026-01-01T00:00:00Z`) rather than `2026-01-01 00:00:00 UTC`. A leap second reads
  as `:59`, and shapes Fizzy does not send read differently at the edges: more than nine
  fractional digits and trailing whitespace are refused, `+05` and `[zone]` suffixes are
  accepted.
- `Retry-After` dates still parse as RFC 2822, a leap second still names the second
  after it, and a comment glued to the zone (`GMT(x)`) is no longer read.

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
