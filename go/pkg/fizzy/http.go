package fizzy

import (
	"context"
	"net/http"
	"time"
)

// Default values for HTTP client configuration.
// These can be overridden using functional options.
const (
	DefaultMaxRetries = 3
	DefaultBaseDelay  = 1 * time.Second
	DefaultMaxJitter  = 100 * time.Millisecond
	DefaultTimeout    = 30 * time.Second
	DefaultMaxPages   = 10000
)

// HTTPOptions configures the HTTP client behavior.
type HTTPOptions struct {
	// Timeout is the request timeout (default: 30s).
	Timeout time.Duration

	// MaxRetries is the total attempt count for retryable requests (default: 3;
	// 0 means no retry — exactly one attempt). GET, PUT, PATCH, DELETE, and HEAD
	// are always retryable. POST is retryable only when marked idempotent via
	// WithIdempotent(ctx).
	MaxRetries int

	// BaseDelay is the initial backoff delay (default: 1s).
	BaseDelay time.Duration

	// MaxJitter is the maximum random jitter to add to delays (default: 100ms).
	MaxJitter time.Duration

	// MaxPages is the maximum pages to fetch in GetAll (default: 10000).
	MaxPages int

	// Transport is the HTTP transport to use. If nil, a default transport
	// with sensible connection pooling is created.
	Transport http.RoundTripper
}

// DefaultHTTPOptions returns HTTPOptions with sensible defaults.
func DefaultHTTPOptions() HTTPOptions {
	return HTTPOptions{
		Timeout:    DefaultTimeout,
		MaxRetries: DefaultMaxRetries,
		BaseDelay:  DefaultBaseDelay,
		MaxJitter:  DefaultMaxJitter,
		MaxPages:   DefaultMaxPages,
	}
}

// WithTimeout sets the HTTP request timeout.
func WithTimeout(d time.Duration) ClientOption {
	return func(c *Client) {
		c.httpOpts.Timeout = d
	}
}

// WithMaxRetries sets the total attempt count for retryable requests: the initial
// request plus its retries. A cap of 0 is floored to one attempt; a negative cap is a
// configuration error.
func WithMaxRetries(n int) ClientOption {
	return func(c *Client) {
		c.httpOpts.MaxRetries = n
	}
}

// WithBaseDelay sets the initial backoff delay.
func WithBaseDelay(d time.Duration) ClientOption {
	return func(c *Client) {
		c.httpOpts.BaseDelay = d
	}
}

// WithMaxJitter sets the maximum random jitter to add to delays.
func WithMaxJitter(d time.Duration) ClientOption {
	return func(c *Client) {
		c.httpOpts.MaxJitter = d
	}
}

// WithMaxPages sets the maximum pages to fetch in GetAll.
func WithMaxPages(n int) ClientOption {
	return func(c *Client) {
		c.httpOpts.MaxPages = n
	}
}

// WithTransport sets a custom HTTP transport.
func WithTransport(t http.RoundTripper) ClientOption {
	return func(c *Client) {
		c.httpOpts.Transport = t
	}
}

// retryableError wraps an error with retry metadata.
// This allows respecting Retry-After headers from 429 responses.
type retryableError struct {
	err        error
	retryAfter time.Duration
}

func (r *retryableError) Error() string {
	return r.err.Error()
}

func (r *retryableError) Unwrap() error {
	return r.err
}

// newDefaultTransport creates an HTTP transport with sensible defaults.
// It clones http.DefaultTransport to preserve proxy settings, HTTP/2, TLS config.
func newDefaultTransport() http.RoundTripper {
	t := http.DefaultTransport.(*http.Transport).Clone()
	t.MaxIdleConns = 100
	t.MaxIdleConnsPerHost = 10
	t.IdleConnTimeout = 90 * time.Second
	return t
}

// noRetryKey is the context key for disabling retry on a request.
type noRetryKey struct{}

// WithNoRetry returns a context that disables retry for the request.
func WithNoRetry(ctx context.Context) context.Context {
	return context.WithValue(ctx, noRetryKey{}, true)
}

func isNoRetry(ctx context.Context) bool {
	v, _ := ctx.Value(noRetryKey{}).(bool)
	return v
}

// idempotentKey is the context key for marking a POST request as idempotent.
type idempotentKey struct{}

// WithIdempotent returns a context that marks the request as idempotent,
// enabling retry for POST requests that are naturally idempotent (e.g. toggle operations).
func WithIdempotent(ctx context.Context) context.Context {
	return context.WithValue(ctx, idempotentKey{}, true)
}

func isIdempotent(ctx context.Context) bool {
	v, _ := ctx.Value(idempotentKey{}).(bool)
	return v
}

// attemptKey is the context key for tracking request attempt number.
type attemptKey struct{}

// contextWithAttempt adds the request attempt number to the context.
func contextWithAttempt(ctx context.Context, attempt int) context.Context {
	return context.WithValue(ctx, attemptKey{}, attempt)
}

// attemptFromContext extracts the attempt number from context (defaults to 1).
func attemptFromContext(ctx context.Context) int {
	if v := ctx.Value(attemptKey{}); v != nil {
		if attempt, ok := v.(int); ok {
			return attempt
		}
	}
	return 1
}

// projectedRequestKey is the context key marking a request whose URL can be signed: a
// caller's absolute URL, on any origin. The hooks and the debug logger see such a
// request projected to its origin — a storage service can sign the query or the path
// — and its transport failure as its classification alone. An API request's URL
// carries no credential (the token is in the Authorization header), so the hooks see
// it whole.
type projectedRequestKey struct{}

// markProjectedRequest marks ctx as belonging to a request the hooks see projected.
func markProjectedRequest(ctx context.Context) context.Context {
	return context.WithValue(ctx, projectedRequestKey{}, true)
}

// isProjectedRequest reports whether ctx carries the projection marker.
func isProjectedRequest(ctx context.Context) bool {
	v, _ := ctx.Value(projectedRequestKey{}).(bool)
	return v
}

// loggingTransport wraps an http.RoundTripper to log requests and responses,
// and calls observability hooks for all HTTP requests (including generated client).
type loggingTransport struct {
	inner  http.RoundTripper
	client *Client
}

// RoundTrip implements http.RoundTripper with logging and hooks.
func (t *loggingTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	projected := isProjectedRequest(req.Context())
	displayURL := req.URL.String()
	if projected {
		displayURL = projectURL(displayURL, false)
	}
	info := RequestInfo{
		Method:  req.Method,
		URL:     displayURL,
		Attempt: attemptFromContext(req.Context()),
	}
	hookCtx := t.client.hooks.OnRequestStart(req.Context(), info)
	if projected {
		// A hook may hand back a context of its own; the redirect net/http derives
		// from this request must still carry the mark.
		hookCtx = markProjectedRequest(hookCtx)
	}
	startTime := time.Now()

	req = req.WithContext(hookCtx)

	var result RequestResult
	defer func() {
		result.Duration = time.Since(startTime)
		t.client.hooks.OnRequestEnd(hookCtx, info, result)
	}()

	if t.client.logger != nil {
		t.client.logger.Debug("http request",
			"method", req.Method,
			"url", displayURL)
	}

	resp, err := t.inner.RoundTrip(req)

	if err != nil {
		result.Error = err
		if projected {
			// A custom transport's failure is text this package cannot vouch for —
			// a *url.Error of its own, or a message interpolating the URL — so the
			// hooks get its classification alone.
			result.Error, _ = classifyFailure(err)
		}
	} else {
		result.StatusCode = resp.StatusCode
		if resp.StatusCode == 429 || resp.StatusCode == 503 {
			result.RetryAfter = parseRetryAfter(resp.Header.Get("Retry-After"))
		}
		if t.client.logger != nil {
			t.client.logger.Debug("http response",
				"status", resp.StatusCode)
		}
	}

	return resp, err
}
