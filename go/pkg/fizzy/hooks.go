package fizzy

import (
	"context"
	"time"
)

// Hooks provides observability callbacks for SDK operations.
// Implementations can use these hooks for logging, metrics, tracing, etc.
//
// There are two levels of hooks:
//   - Operation-level: OnOperationStart/OnOperationEnd for semantic SDK operations
//   - Request-level: OnRequestStart/OnRequestEnd for HTTP requests
type Hooks interface {
	// OnOperationStart is called when a semantic SDK operation begins.
	OnOperationStart(ctx context.Context, op OperationInfo) context.Context

	// OnOperationEnd is called when a semantic SDK operation completes.
	OnOperationEnd(ctx context.Context, op OperationInfo, err error, duration time.Duration)

	// OnRequestStart is called before an HTTP request is sent.
	OnRequestStart(ctx context.Context, info RequestInfo) context.Context

	// OnRequestEnd is called after an HTTP request completes.
	OnRequestEnd(ctx context.Context, info RequestInfo, result RequestResult)

	// OnRetry is called before a retry attempt.
	OnRetry(ctx context.Context, info RequestInfo, attempt int, err error)
}

// GatingHooks extends Hooks with request gating capability.
// Implementations can reject operations before they execute,
// enabling patterns like circuit breakers, bulkheads, and rate limiters.
type GatingHooks interface {
	Hooks
	// OnOperationGate is called before OnOperationStart.
	// Returns a new context and an error. Return non-nil error to reject the operation.
	OnOperationGate(ctx context.Context, op OperationInfo) (context.Context, error)
}

// RequestInfo contains information about an HTTP request.
type RequestInfo struct {
	Method string
	URL    string
	// Attempt is the current attempt number (1-indexed).
	Attempt int
}

// OperationInfo describes a semantic SDK operation.
type OperationInfo struct {
	// Service is the logical service (e.g., "Cards", "Boards").
	Service string
	// Operation is the specific method (e.g., "List", "Create", "Close").
	Operation string
	// ResourceType is the Fizzy resource type (e.g., "card", "board").
	ResourceType string
	// IsMutation indicates if this operation modifies state.
	IsMutation bool
	// ResourceID is the specific resource ID if applicable.
	ResourceID int64
}

// RequestResult contains the result of an HTTP request.
type RequestResult struct {
	// StatusCode is the HTTP status code (0 if request failed before response).
	StatusCode int
	// Duration is the time taken for the request.
	Duration time.Duration
	// Error is non-nil if the request failed.
	Error error
	// FromCache indicates the response was served from cache.
	FromCache bool
	// Retryable indicates whether this error will be retried.
	Retryable bool
	// RetryAfter is the Retry-After header value in seconds (0 if not present).
	RetryAfter int
}
