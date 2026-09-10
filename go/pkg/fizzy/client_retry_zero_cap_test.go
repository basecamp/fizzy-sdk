package fizzy

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

// MaxRetries is the total attempt count, and a cap of zero means "no retries — exactly
// one attempt", not "no request". The raw GET loop is pre-check, so without a floor a
// zero cap sends nothing and returns a wrapped nil error.

type retryRecordingHooks struct {
	NoopHooks
	next []int
}

func (h *retryRecordingHooks) OnRetry(_ context.Context, _ RequestInfo, attempt int, _ error) {
	h.next = append(h.next, attempt)
}

func TestClient_ZeroMaxRetriesMakesExactlyOneGetRequest(t *testing.T) {
	var requests int32
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		atomic.AddInt32(&requests, 1)
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"ok":true}`))
	}))
	defer server.Close()

	hooks := &retryRecordingHooks{}
	client := NewClient(&Config{BaseURL: server.URL}, &StaticTokenProvider{Token: "test-token"},
		WithMaxRetries(0), WithBaseDelay(time.Millisecond), WithMaxJitter(time.Millisecond), WithHooks(hooks))

	resp, err := client.Get(context.Background(), "/cards/1")
	if err != nil {
		t.Fatalf("expected the one attempt to succeed, got %v", err)
	}
	if got := atomic.LoadInt32(&requests); got != 1 {
		t.Errorf("requests = %d, want exactly 1", got)
	}
	if resp.StatusCode != http.StatusOK || string(resp.Data) != `{"ok":true}` {
		t.Errorf("got %d %q, want the server's real response", resp.StatusCode, resp.Data)
	}
	if len(hooks.next) != 0 {
		t.Errorf("OnRetry fired for attempts %v with no retry budget", hooks.next)
	}
}

func TestClient_ZeroMaxRetriesReturnsTheOneAttemptsError(t *testing.T) {
	var requests int32
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		atomic.AddInt32(&requests, 1)
		w.WriteHeader(http.StatusServiceUnavailable) // retryable — a retry would show
	}))
	defer server.Close()

	// Zero jitter is an accepted option; the final attempt must not compute a
	// backoff it will never sleep, since rand.Int63n(0) panics.
	hooks := &retryRecordingHooks{}
	client := NewClient(&Config{BaseURL: server.URL}, &StaticTokenProvider{Token: "test-token"},
		WithMaxRetries(0), WithBaseDelay(time.Millisecond), WithMaxJitter(0), WithHooks(hooks))

	_, err := client.Get(context.Background(), "/cards/1")
	if err == nil {
		t.Fatal("expected the 503 to surface as an error")
	}
	if got := atomic.LoadInt32(&requests); got != 1 {
		t.Errorf("requests = %d, want exactly 1", got)
	}
	var apiErr *Error
	if !errors.As(err, &apiErr) || apiErr.HTTPStatus != http.StatusServiceUnavailable {
		t.Fatalf("expected the 503 *Error in the chain, got %T: %v", err, err)
	}
	if !strings.Contains(err.Error(), "after 1 attempt:") || strings.Contains(err.Error(), "<nil>") {
		t.Errorf("error should name the one attempt and wrap the real failure, got %q", err)
	}
	if len(hooks.next) != 0 {
		t.Errorf("OnRetry fired for attempts %v after the final attempt", hooks.next)
	}
}

func TestClient_ExhaustedAttemptsWrapTheLastError(t *testing.T) {
	var requests int32
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		atomic.AddInt32(&requests, 1)
		w.WriteHeader(http.StatusServiceUnavailable)
	}))
	defer server.Close()

	hooks := &retryRecordingHooks{}
	client := NewClient(&Config{BaseURL: server.URL}, &StaticTokenProvider{Token: "test-token"},
		WithMaxRetries(2), WithBaseDelay(time.Millisecond), WithMaxJitter(time.Millisecond), WithHooks(hooks))

	_, err := client.Get(context.Background(), "/cards/1")
	if err == nil {
		t.Fatal("expected the 503s to surface as an error")
	}
	if got := atomic.LoadInt32(&requests); got != 2 {
		t.Errorf("requests = %d, want the whole budget of 2", got)
	}
	var apiErr *Error
	if !errors.As(err, &apiErr) || apiErr.HTTPStatus != http.StatusServiceUnavailable {
		t.Fatalf("expected the 503 *Error in the chain, got %T: %v", err, err)
	}
	if !strings.Contains(err.Error(), "after 2 attempts:") {
		t.Errorf("error should count attempts, got %q", err)
	}
	if len(hooks.next) != 1 || hooks.next[0] != 2 {
		t.Errorf("OnRetry should announce attempt 2 only, got %v", hooks.next)
	}
}

func TestBackoffDelayWithZeroJitterIsDeterministic(t *testing.T) {
	client := NewClient(&Config{BaseURL: "https://fizzy.example.com"}, &StaticTokenProvider{Token: "test-token"},
		WithBaseDelay(10*time.Millisecond), WithMaxJitter(0))

	for attempt, want := range map[int]time.Duration{1: 10 * time.Millisecond, 2: 20 * time.Millisecond, 3: 40 * time.Millisecond} {
		if got := client.backoffDelay(attempt); got != want {
			t.Errorf("backoffDelay(%d) = %v, want %v", attempt, got, want)
		}
	}
}
