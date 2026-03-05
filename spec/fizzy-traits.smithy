$version: "2"

namespace fizzy.traits

use smithy.openapi#specificationExtension

// ─── Retry ───────────────────────────────────────────────────────────────
// Per-operation retry configuration. Applied via @fizzyRetry on each
// operation in the Smithy model; emitted as x-fizzy-retry in OpenAPI.

@trait(selector: "operation")
@specificationExtension(as: "x-fizzy-retry")
structure fizzyRetry {
    @required
    maxAttempts: Integer

    baseDelayMs: Integer

    backoff: String

    retryOn: RetryStatusCodes
}

list RetryStatusCodes {
    member: Integer
}

// ─── Pagination ──────────────────────────────────────────────────────────
// Link-header pagination. Fizzy uses `rel="next"` with `?page=N`.
// No X-Total-Count header (unlike Basecamp).

@trait(selector: "operation")
@specificationExtension(as: "x-fizzy-pagination")
structure fizzyPagination {
    @required
    style: String

    @required
    pageParam: String

    maxPageSize: Integer
}

// ─── Idempotency ─────────────────────────────────────────────────────────
// Marks operations as naturally idempotent (same input → same state).
// Used by generators to decide retry behavior.

@trait(selector: "operation")
@specificationExtension(as: "x-fizzy-idempotent")
structure fizzyIdempotent {
    natural: Boolean
}

// ─── Sensitive ───────────────────────────────────────────────────────────
// Applied to structure members containing PII. Generators use this to
// redact values in logs and hook payloads.

@trait(selector: "structure > member")
@specificationExtension(as: "x-fizzy-sensitive")
structure fizzySensitive {
    @required
    category: String

    redact: Boolean
}
