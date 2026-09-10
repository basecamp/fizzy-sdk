package fizzy

import (
	"context"
	"errors"
	"fmt"
	"net"
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
	if !strings.Contains(sdkErr.Hint, "connection refused") {
		t.Errorf("on the API origin the transport's own diagnostic should survive, got %q", sdkErr.Hint)
	}

	// Off the API origin — a caller-supplied absolute URL, the shape a signed storage
	// URL takes — only the failure's classification survives beneath the projection.
	_, err = client.Get(context.Background(), "https://127.0.0.1:1/x?sig=SECRETVALUE")
	if err == nil {
		t.Fatal("expected a network error dialing a closed port")
	}
	if !errors.As(err, &sdkErr) || sdkErr.Code != CodeNetwork {
		t.Fatalf("expected a network *Error, got %T: %v", err, err)
	}
	for _, text := range append(renderings(err), sdkErr.Hint, sdkErr.Message) {
		if strings.Contains(text, "SECRETVALUE") {
			t.Errorf("the signed query leaked into %q", text)
		}
	}
	if want := `Get "https://127.0.0.1:1/x": transport failure`; sdkErr.Hint != want {
		t.Errorf("hint = %q, want %q", sdkErr.Hint, want)
	}
}

func TestRedactTransportError(t *testing.T) {
	signed := &url.Error{Op: "Get", URL: "https://user:pw@storage.example.com/blob/1?sig=SECRETVALUE#frag", Err: context.Canceled}

	t.Run("projects the URL of a bare transport error and keeps its classification", func(t *testing.T) {
		got := redactTransportError(signed, "")
		want := `Get "https://storage.example.com/blob/1": context canceled`
		if got.Error() != want {
			t.Errorf("got %q, want %q", got.Error(), want)
		}
		if !errors.Is(got, context.Canceled) {
			t.Error("the cause chain should still reach the context sentinel")
		}
	})

	t.Run("drops a wrapper around the projection, whatever its text carried", func(t *testing.T) {
		for name, wrapped := range map[string]error{
			"prefix":           fmt.Errorf("fetching the blob: %w", signed),
			"interpolated URL": fmt.Errorf("request %s failed: %w", signed.URL, signed),
			"opaque":           &opaqueWrapperError{cause: signed},
		} {
			got := redactTransportError(wrapped, "")
			if want := `Get "https://storage.example.com/blob/1": context canceled`; got.Error() != want {
				t.Errorf("%s: got %q, want %q", name, got.Error(), want)
			}
			var urlErr *url.Error
			if !errors.As(got, &urlErr) || urlErr.URL != "https://storage.example.com/blob/1" {
				t.Errorf("%s: should unwrap to the projected *url.Error, got %v", name, got)
			}
			if !errors.Is(got, context.Canceled) {
				t.Errorf("%s: the cause chain should still reach the context sentinel", name)
			}
		}
	})

	t.Run("keeps only the classification beneath a projected URL", func(t *testing.T) {
		opaque := &url.Error{Op: "Put", URL: "https://storage.example.com/blob/1?sig=SECRETVALUE", Err: timeoutError{}}
		got := redactTransportError(opaque, "")
		if want := `Put "https://storage.example.com/blob/1": transport timeout`; got.Error() != want {
			t.Errorf("got %q, want %q", got.Error(), want)
		}
		for _, text := range renderings(got) {
			if strings.Contains(text, "SECRETVALUE") {
				t.Errorf("the signed query leaked into %q", text)
			}
		}
		var netErr net.Error
		if !errors.As(got, &netErr) || !netErr.Timeout() {
			t.Errorf("the timeout classification should survive, got %v", got)
		}
		plain := redactTransportError(&url.Error{Op: "Put", URL: "https://storage.example.com/blob/1?sig=SECRETVALUE", Err: errors.New("connection refused")}, "")
		if want := `Put "https://storage.example.com/blob/1": transport failure`; plain.Error() != want {
			t.Errorf("got %q, want %q", plain.Error(), want)
		}
		if !errors.As(plain, &netErr) || netErr.Timeout() {
			t.Errorf("a refused connection should not classify as a timeout, got %v", plain)
		}
	})

	t.Run("projects every transport error in a nested chain", func(t *testing.T) {
		outer := &url.Error{Op: "Get", URL: "https://proxy.example.com/relay", Err: signed}
		got := redactTransportError(outer, "")
		want := `Get "https://proxy.example.com/relay": Get "https://storage.example.com/blob/1": context canceled`
		if got.Error() != want {
			t.Errorf("got %q, want %q", got.Error(), want)
		}
		for _, text := range renderings(got) {
			if strings.Contains(text, "SECRETVALUE") {
				t.Errorf("the signed query leaked into %q", text)
			}
		}
		if got = redactTransportError(fmt.Errorf("relaying to %s: %w", outer.URL, outer), ""); got.Error() != want {
			t.Errorf("got %q, want %q", got.Error(), want)
		}
	})

	t.Run("projects every member of a joined error and keeps the rest", func(t *testing.T) {
		other := &url.Error{Op: "Get", URL: "https://other.example.com/x?token=SECRETVALUE", Err: errors.New("reset")}
		got := redactTransportError(errors.Join(signed, context.DeadlineExceeded, other), "")
		want := "Get \"https://storage.example.com/blob/1\": context canceled\ncontext deadline exceeded\nGet \"https://other.example.com/x\": transport failure"
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

	t.Run("builds a projected transport error from fixed parts alone", func(t *testing.T) {
		const signedURL = "https://storage.example.com/blob/1?sig=SECRETVALUE"
		cancelledTimeout := &url.Error{Op: "fetch " + signedURL, URL: signedURL, Err: cancelledTimeoutError{}}
		got := redactTransportError(cancelledTimeout, "")
		if want := `Request "https://storage.example.com/blob/1": context canceled`; got.Error() != want {
			t.Errorf("got %q, want %q", got.Error(), want)
		}
		for _, text := range renderings(got) {
			if strings.Contains(text, "SECRETVALUE") {
				t.Errorf("the signed query leaked into %q", text)
			}
		}
		var netErr net.Error
		if !errors.Is(got, context.Canceled) || !errors.As(got, &netErr) || !netErr.Timeout() {
			t.Errorf("the cancellation and the timeout classification should both survive, got %v", got)
		}

		joined := redactTransportError(errors.Join(signed, fmt.Errorf("request %s failed", signedURL), context.DeadlineExceeded), "")
		if want := "Get \"https://storage.example.com/blob/1\": context canceled\ncontext deadline exceeded"; joined.Error() != want {
			t.Errorf("got %q, want %q", joined.Error(), want)
		}
		if !errors.Is(joined, context.Canceled) || !errors.Is(joined, context.DeadlineExceeded) {
			t.Error("the sentinel siblings should still be reachable through the chain")
		}
	})

	t.Run("keeps the cause beneath a URL on the API origin", func(t *testing.T) {
		api := &url.Error{Op: "Get", URL: "https://api.example.com/boxes?page=2", Err: errors.New("connection refused")}
		got := redactTransportError(api, "https://api.example.com")
		if want := `Get "https://api.example.com/boxes": connection refused`; got.Error() != want {
			t.Errorf("got %q, want %q", got.Error(), want)
		}
		off := redactTransportError(api, "https://other.example.com")
		if want := `Get "https://api.example.com/boxes": transport failure`; off.Error() != want {
			t.Errorf("got %q, want %q", off.Error(), want)
		}
	})

	t.Run("returns an error with nothing to drop unchanged", func(t *testing.T) {
		plain := &url.Error{Op: "Get", URL: "https://api.example.com/x", Err: context.Canceled}
		if got := redactTransportError(plain, ""); got != plain { //nolint:errorlint // identity is the point
			t.Errorf("got %v, want the same error", got)
		}
		other := errors.New("not a transport error")
		if got := redactTransportError(other, ""); got != other { //nolint:errorlint // identity is the point
			t.Errorf("got %v, want the same error", got)
		}
		nested := &url.Error{Op: "Get", URL: "https://proxy.example.com/relay", Err: plain}
		if got := redactTransportError(nested, ""); got != nested { //nolint:errorlint // identity is the point
			t.Errorf("got %v, want the same error", got)
		}
		wrapped := fmt.Errorf("fetching: %w", plain)
		if got := redactTransportError(wrapped, ""); got != wrapped { //nolint:errorlint // identity is the point
			t.Errorf("got %v, want the same error", got)
		}
	})

	t.Run("projects an unparsable URL to a fixed token", func(t *testing.T) {
		bad := &url.Error{Op: "Get", URL: "http://[::1/x?sig=SECRETVALUE", Err: context.Canceled}
		got := redactTransportError(bad, "")
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

// timeoutError is a custom transport's failure: it classifies as a timeout and, being
// text this package did not build, renders the request URL on its own.
type timeoutError struct{}

func (timeoutError) Error() string {
	return "request https://storage.example.com/blob/1?sig=SECRETVALUE failed: i/o timeout"
}
func (timeoutError) Timeout() bool   { return true }
func (timeoutError) Temporary() bool { return true }

// cancelledTimeoutError is a custom transport's failure that wraps a cancellation and
// classifies as a timeout at once.
type cancelledTimeoutError struct{}

func (cancelledTimeoutError) Error() string   { return "cancelled: " + context.Canceled.Error() }
func (cancelledTimeoutError) Unwrap() error   { return context.Canceled }
func (cancelledTimeoutError) Timeout() bool   { return true }
func (cancelledTimeoutError) Temporary() bool { return false }

// opaqueWrapperError wraps an error without rendering it.
type opaqueWrapperError struct{ cause error }

func (w *opaqueWrapperError) Error() string { return "request failed" }
func (w *opaqueWrapperError) Unwrap() error { return w.cause }
