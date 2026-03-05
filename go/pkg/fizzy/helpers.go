package fizzy

import (
	"fmt"
	"net/http"
)

// checkResponse converts HTTP response errors to SDK errors for non-2xx responses.
// Used by all service methods that call the generated client.
//
//nolint:unused // Used by generated service code
func checkResponse(resp *http.Response) error {
	if resp == nil {
		return nil
	}
	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		return nil
	}

	requestID := resp.Header.Get("X-Request-Id")

	switch resp.StatusCode {
	case http.StatusUnauthorized:
		return &Error{Code: CodeAuth, Message: "authentication required", HTTPStatus: 401, RequestID: requestID}
	case http.StatusForbidden:
		return &Error{Code: CodeForbidden, Message: "access denied", HTTPStatus: 403, RequestID: requestID}
	case http.StatusNotFound:
		return &Error{Code: CodeNotFound, Message: "resource not found", HTTPStatus: 404, RequestID: requestID}
	case http.StatusUnprocessableEntity:
		return &Error{Code: CodeValidation, Message: "validation error", HTTPStatus: 422, RequestID: requestID}
	case http.StatusTooManyRequests:
		return &Error{Code: CodeRateLimit, Message: "rate limited - try again later", HTTPStatus: 429, Retryable: true, RequestID: requestID}
	default:
		retryable := resp.StatusCode >= 500 && resp.StatusCode < 600
		return &Error{Code: CodeAPI, Message: fmt.Sprintf("API error: %s", resp.Status), HTTPStatus: resp.StatusCode, Retryable: retryable, RequestID: requestID}
	}
}

// derefInt64 safely dereferences a pointer, returning 0 if nil.
//
//nolint:unused // Used by generated service code
func derefInt64(p *int64) int64 {
	if p == nil {
		return 0
	}
	return *p
}

// ListMeta contains pagination metadata from list operations.
// Fizzy does not emit X-Total-Count headers; pagination relies on Link headers.
type ListMeta struct{}
