package fizzy

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"strings"
	"testing"
	"time"
)

// renderings is every text a caller or a logger can get out of err: its Error, its
// %+v, and the Error of every link of its cause chain.
func renderings(err error) []string {
	out := []string{err.Error(), fmt.Sprintf("%+v", err)}
	for cause := errors.Unwrap(err); cause != nil; cause = errors.Unwrap(cause) {
		out = append(out, cause.Error(), fmt.Sprintf("%+v", cause))
	}
	return out
}

// TestNetworkErrorRendersNoSignedQuery forces a dial failure through the shipped client
// against a URL whose query is a credential and checks the signature reaches none of
// the error's renderings: net/http's *url.Error carries the whole URL, and ErrNetwork
// used to copy it into the hint verbatim.
func TestNetworkErrorRendersNoSignedQuery(t *testing.T) {
	client := NewClient(&Config{BaseURL: "http://127.0.0.1:1"}, &StaticTokenProvider{Token: "test"},
		WithMaxRetries(1), WithBaseDelay(time.Millisecond), WithMaxJitter(time.Millisecond))

	_, err := client.Get(context.Background(), "/x?sig=SECRETVALUE")
	if err == nil {
		t.Fatal("expected a network error dialing a closed port")
	}
	var sdkErr *Error
	if !errors.As(err, &sdkErr) || sdkErr.Code != CodeNetwork {
		t.Fatalf("expected a network *Error, got %T: %v", err, err)
	}
	for _, text := range append(renderings(err), sdkErr.Hint, sdkErr.Message) {
		if strings.Contains(text, "SECRETVALUE") {
			t.Errorf("the signed query leaked into %q", text)
		}
	}
	if !strings.Contains(sdkErr.Hint, `"http://127.0.0.1:1/x"`) {
		t.Errorf("hint should keep the URL's scheme, host and path, got %q", sdkErr.Hint)
	}
	var urlErr *url.Error
	if !errors.As(err, &urlErr) {
		t.Fatalf("the cause chain should still classify as a *url.Error, got %v", err)
	}
	if urlErr.URL != "http://127.0.0.1:1/x" {
		t.Errorf("chained *url.Error URL = %q, want the projection", urlErr.URL)
	}
}

func TestRedactTransportError(t *testing.T) {
	signed := &url.Error{Op: "Get", URL: "https://user:pw@storage.example.com/blob/1?sig=SECRETVALUE#frag", Err: context.Canceled}

	t.Run("projects the URL of a bare transport error and keeps its classification", func(t *testing.T) {
		got := redactTransportError(signed)
		want := `Get "https://storage.example.com/blob/1": context canceled`
		if got.Error() != want {
			t.Errorf("got %q, want %q", got.Error(), want)
		}
		if !errors.Is(got, context.Canceled) {
			t.Error("the cause chain should still reach the context sentinel")
		}
	})

	t.Run("keeps a wrapper's text around the projection", func(t *testing.T) {
		got := redactTransportError(fmt.Errorf("fetching the blob: %w", signed))
		want := `fetching the blob: Get "https://storage.example.com/blob/1": context canceled`
		if got.Error() != want {
			t.Errorf("got %q, want %q", got.Error(), want)
		}
		var urlErr *url.Error
		if !errors.As(got, &urlErr) || urlErr.URL != "https://storage.example.com/blob/1" {
			t.Errorf("should unwrap to the projected *url.Error, got %v", got)
		}
		if !errors.Is(got, context.Canceled) {
			t.Error("the cause chain should still reach the context sentinel")
		}
	})

	t.Run("keeps only the transport error when a wrapper hides the URL", func(t *testing.T) {
		hidden := &opaqueWrapperError{cause: signed}
		got := redactTransportError(hidden)
		if strings.Contains(got.Error(), "SECRETVALUE") {
			t.Errorf("the signed query leaked into %q", got.Error())
		}
		if got.Error() != `Get "https://storage.example.com/blob/1": context canceled` {
			t.Errorf("got %q", got.Error())
		}
	})

	t.Run("projects every transport error in a nested chain", func(t *testing.T) {
		outer := &url.Error{Op: "Get", URL: "https://proxy.example.com/relay", Err: signed}
		got := redactTransportError(outer)
		want := `Get "https://proxy.example.com/relay": Get "https://storage.example.com/blob/1": context canceled`
		if got.Error() != want {
			t.Errorf("got %q, want %q", got.Error(), want)
		}
		for _, text := range renderings(got) {
			if strings.Contains(text, "SECRETVALUE") {
				t.Errorf("the signed query leaked into %q", text)
			}
		}
		got = redactTransportError(fmt.Errorf("relaying: %w", outer))
		if got.Error() != "relaying: "+want {
			t.Errorf("got %q, want %q", got.Error(), "relaying: "+want)
		}
	})

	t.Run("projects every member of a joined error and keeps the rest", func(t *testing.T) {
		other := &url.Error{Op: "Get", URL: "https://other.example.com/x?token=SECRETVALUE", Err: errors.New("reset")}
		got := redactTransportError(errors.Join(signed, context.DeadlineExceeded, other))
		want := "Get \"https://storage.example.com/blob/1\": context canceled\ncontext deadline exceeded\nGet \"https://other.example.com/x\": reset"
		if got.Error() != want {
			t.Errorf("got %q, want %q", got.Error(), want)
		}
		if !errors.Is(got, context.Canceled) || !errors.Is(got, context.DeadlineExceeded) {
			t.Error("every member should still be reachable through the chain")
		}
		for _, text := range renderings(got) {
			if strings.Contains(text, "SECRETVALUE") {
				t.Errorf("the signed query leaked into %q", text)
			}
		}
	})

	t.Run("returns an error with nothing to drop unchanged", func(t *testing.T) {
		plain := &url.Error{Op: "Get", URL: "https://api.example.com/x", Err: context.Canceled}
		if got := redactTransportError(plain); got != plain { //nolint:errorlint // identity is the point
			t.Errorf("got %v, want the same error", got)
		}
		other := errors.New("not a transport error")
		if got := redactTransportError(other); got != other { //nolint:errorlint // identity is the point
			t.Errorf("got %v, want the same error", got)
		}
		nested := &url.Error{Op: "Get", URL: "https://proxy.example.com/relay", Err: plain}
		if got := redactTransportError(nested); got != nested { //nolint:errorlint // identity is the point
			t.Errorf("got %v, want the same error", got)
		}
	})

	t.Run("projects an unparsable URL to a fixed token", func(t *testing.T) {
		bad := &url.Error{Op: "Get", URL: "http://[::1/x?sig=SECRETVALUE", Err: context.Canceled}
		got := redactTransportError(bad)
		if strings.Contains(got.Error(), "SECRETVALUE") || !strings.Contains(got.Error(), `"unparsable"`) {
			t.Errorf("got %q", got.Error())
		}
	})
}

func TestAsErrorRendersNoSignedQuery(t *testing.T) {
	signed := &url.Error{Op: "Put", URL: "https://storage.example.com/blob?sig=SECRETVALUE", Err: errors.New("connection reset")}
	e := AsError(signed)
	for _, text := range append(renderings(e), e.Message) {
		if strings.Contains(text, "SECRETVALUE") {
			t.Errorf("the signed query leaked into %q", text)
		}
	}
}

// opaqueWrapperError wraps an error without rendering it.
type opaqueWrapperError struct{ cause error }

func (w *opaqueWrapperError) Error() string { return "request failed" }
func (w *opaqueWrapperError) Unwrap() error { return w.cause }
