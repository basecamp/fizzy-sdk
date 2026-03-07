# Fizzy SDK Security

This document describes the security properties enforced across all Fizzy SDK language implementations.

## HTTPS Enforcement

All SDK clients reject `http://` base URLs by default. Only `https://` URLs are accepted for API communication. The sole exception is `localhost` (and `127.0.0.1`), which is permitted for local development and testing.

## Credential Protection

The SDK transmits credentials via the `Authorization` header using Bearer token authentication. Cookies received from the API are stored in-memory only and scoped to the configured base URL. Credentials are never written to disk, logged, or included in error messages.

## Response Size Limits

All HTTP responses are subject to a maximum body size (`MAX_RESPONSE_BODY_BYTES`). Responses exceeding this limit are rejected before full consumption to prevent memory exhaustion attacks. The default limit is generous enough for normal API usage but prevents unbounded allocation.

## Retry Semantics

Retry behavior varies by SDK and is driven by a per-operation behavior model generated from the Smithy spec. The general policy:

- **Non-idempotent operations** (e.g., `CreateCard`, `CreateBoard`) have `maxAttempts: 1` — they are never retried, preventing duplicate side effects.
- **Idempotent operations** (reads plus `PUT`, `PATCH`, `DELETE`, and select `POST` actions like `CloseCard`, `GoldCard`) may retry up to 3 times on `429`, `500`, and `503` responses.
- **Go** retries all methods except `POST` by default. Operations with `retry_on: null` in the behavior model can opt out via `WithNoRetry(ctx)`.
- **Ruby** retries all methods except `POST` by default. Operations with `retry_on: null` can opt out via `retryable: false`.
- **Kotlin** retries `GET`, `PUT`, `PATCH`, `DELETE`, and `HEAD` by default, and can additionally retry `POST` when the operation's metadata marks it as idempotent.
- **TypeScript and Swift** use the full per-operation retry config from the behavior model.

All retries use exponential backoff with jitter. The `Retry-After` header is respected when present on `429` responses.

## Header Redaction in Logs

When debug logging is enabled, the SDK redacts sensitive headers before output. The `Authorization` header value is replaced with `[REDACTED]`. Cookie values are similarly redacted. This prevents credential leakage through application logs.

## Webhook Signature Verification

Incoming webhook payloads can be verified using HMAC-SHA256 signatures. The SDK provides a verification function that:

- Computes HMAC-SHA256 over the raw request body using the shared secret
- Compares the computed signature against the `X-Fizzy-Signature` header using constant-time comparison
- Rejects payloads with missing, malformed, or mismatched signatures

## Pagination Origin Enforcement

When following `Link` header URLs for pagination, the SDK validates that each URL shares the same origin (scheme, host, port) as the configured base URL. This prevents open-redirect attacks where a malicious server could direct the client to an attacker-controlled endpoint.

## Concurrency Safety

Each language implementation provides concurrency-safe client instances:

- **Go**: The `Client` struct is safe for concurrent use. HTTP client and token state are protected appropriately.
- **TypeScript**: The client is safe for concurrent `async` usage within a single event loop. No shared mutable state between requests.
- **Ruby**: The client is thread-safe. Internal state is protected by a `Mutex` where needed.
- **Kotlin**: The client uses `ConcurrentHashMap` for JVM service caching via `getOrPut`. HTTP operations are coroutine-safe.
- **Swift**: The client uses `NSLock` to serialize service cache access and resilience state (circuit breaker, bulkhead, rate limiter, ETag cache). Fields guarded by locks are marked `nonisolated(unsafe)`.
