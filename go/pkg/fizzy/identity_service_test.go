package fizzy

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

func TestIdentityUpdateTimezone(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPatch {
			t.Fatalf("method = %s, want PATCH", r.Method)
		}
		if r.URL.Path != "/999/my/timezone.json" {
			t.Fatalf("path = %s, want /999/my/timezone.json", r.URL.Path)
		}
		w.WriteHeader(http.StatusNoContent)
	}))
	defer server.Close()

	client := NewClient(&Config{BaseURL: server.URL}, &StaticTokenProvider{Token: "test"})
	_, err := client.Identity().UpdateMyTimezone(context.Background(), "999", &generated.UpdateMyTimezoneRequest{TimezoneName: "America/New_York"})
	if err != nil {
		t.Fatalf("UpdateMyTimezone: %v", err)
	}
}

func TestPinsListUsesAccountScopedPath(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			t.Fatalf("method = %s, want GET", r.Method)
		}
		if r.URL.Path != "/999/my/pins.json" {
			t.Fatalf("path = %s, want /999/my/pins.json", r.URL.Path)
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`[]`))
	}))
	defer server.Close()

	client := NewClient(&Config{BaseURL: server.URL}, &StaticTokenProvider{Token: "test"})
	_, _, err := client.ForAccount("999").Pins().List(context.Background())
	if err != nil {
		t.Fatalf("ListPins: %v", err)
	}
}
