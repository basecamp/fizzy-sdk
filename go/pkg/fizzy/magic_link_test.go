package fizzy

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
)

// fizzySessions answers the two halves of a magic-link sign-in as Fizzy does: 201 with
// the pending token for {email_address} at /session.json, and the session for {code} at
// /session/magic_link.json only when the pending token comes back as the cookie.
func fizzySessions(t *testing.T, pending string) *httptest.Server {
	t.Helper()
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		var params map[string]any
		_ = json.Unmarshal(body, &params)
		w.Header().Set("Content-Type", "application/json")
		switch {
		case r.Method == http.MethodPost && r.URL.Path == "/session.json":
			if params["email_address"] != "jane@example.com" || len(params) != 1 {
				t.Errorf("create session body = %s, want only email_address", body)
			}
			w.WriteHeader(http.StatusCreated)
			_, _ = io.WriteString(w, `{"pending_authentication_token":"`+pending+`"}`)
		case r.Method == http.MethodPost && r.URL.Path == "/session/magic_link.json":
			if params["code"] != "ABC123" || len(params) != 1 {
				t.Errorf("redeem body = %s, want only code", body)
			}
			cookie, err := r.Cookie(PendingAuthenticationCookie)
			if err != nil || cookie.Value == "" {
				w.WriteHeader(http.StatusUnauthorized)
				_, _ = io.WriteString(w, `{"message":"Enter your email address to sign in."}`)
				return
			}
			if r.Header.Get("Authorization") != "" {
				t.Errorf("redeem sent an Authorization header")
			}
			w.Header().Set("X-Pending-Seen", cookie.Value)
			_, _ = io.WriteString(w, `{"session_token":"st-1","requires_signup_completion":false}`)
		default:
			t.Errorf("unexpected %s %s", r.Method, r.URL.Path)
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	t.Cleanup(server.Close)
	return server
}

func TestMagicLinkFlowSignsInThroughFizzysSessionRoutes(t *testing.T) {
	server := fizzySessions(t, "pend-1")
	flow := NewMagicLinkFlow(server.URL, nil)

	pending, err := flow.CreateSession(context.Background(), "jane@example.com")
	if err != nil {
		t.Fatalf("CreateSession: %v", err)
	}
	if pending.PendingAuthenticationToken != "pend-1" || flow.PendingToken() != "pend-1" {
		t.Fatalf("pending = %+v, flow keeps %q; want pend-1", pending, flow.PendingToken())
	}

	session, err := flow.RedeemMagicLink(context.Background(), "ABC123")
	if err != nil {
		t.Fatalf("RedeemMagicLink: %v", err)
	}
	if session.SessionToken != "st-1" || session.RequiresSignupCompletion {
		t.Errorf("session = %+v, want st-1 with no signup to complete", session)
	}
	if flow.PendingToken() != "" {
		t.Errorf("the pending token outlived its redeem")
	}
}

// A token Fizzy hands out can carry characters a cookie cannot; it goes out escaped, as
// Rack unescapes it.
func TestMagicLinkFlowEscapesThePendingCookie(t *testing.T) {
	var seen string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		seen = r.Header.Get("Cookie")
		w.Header().Set("Content-Type", "application/json")
		_, _ = io.WriteString(w, `{"session_token":"st-1","requires_signup_completion":true}`)
	}))
	t.Cleanup(server.Close)

	flow := ResumeMagicLinkFlow(server.URL, nil, "eyJ a/b+c==--d")
	session, err := flow.RedeemMagicLink(context.Background(), "ABC123")
	if err != nil {
		t.Fatalf("RedeemMagicLink: %v", err)
	}
	if want := "pending_authentication_token=eyJ%20a%2Fb%2Bc%3D%3D--d"; seen != want {
		t.Errorf("Cookie = %q, want %q", seen, want)
	}
	if !session.RequiresSignupCompletion {
		t.Errorf("requires_signup_completion was lost")
	}
}

func TestMagicLinkFlowResumesWithAPendingTokenFromAnotherProcess(t *testing.T) {
	server := fizzySessions(t, "unused")
	flow := ResumeMagicLinkFlow(server.URL, nil, "pend-9")

	session, err := flow.RedeemMagicLink(context.Background(), "ABC123")
	if err != nil {
		t.Fatalf("RedeemMagicLink: %v", err)
	}
	if session.SessionToken != "st-1" {
		t.Errorf("session = %+v", session)
	}
}

func TestMagicLinkFlowRefusesARedeemWithNothingPending(t *testing.T) {
	server := fizzySessions(t, "unused")
	flow := NewMagicLinkFlow(server.URL, nil)

	_, err := flow.RedeemMagicLink(context.Background(), "ABC123")
	if e := AsError(err); e == nil || e.Code != CodeUsage {
		t.Fatalf("err = %v, want a usage error", err)
	}
}

// Fizzy answers 401 for a wrong code or a missing cookie, and that is an auth error, not
// a retry.
func TestMagicLinkFlowReportsARefusedCodeAsAnAuthError(t *testing.T) {
	requests := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requests++
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		_, _ = io.WriteString(w, `{"message":"Try another code."}`)
	}))
	t.Cleanup(server.Close)
	flow := ResumeMagicLinkFlow(server.URL, nil, "pend-1")

	_, err := flow.RedeemMagicLink(context.Background(), "WRONG1")
	if e := AsError(err); e == nil || e.Code != CodeAuth || e.HTTPStatus != http.StatusUnauthorized {
		t.Fatalf("err = %v, want an auth error", err)
	}
	if requests != 1 {
		t.Errorf("requests = %d, want 1", requests)
	}
	if flow.PendingToken() != "pend-1" {
		t.Errorf("a refused code dropped the pending token; the person can still try again")
	}
}

func TestMagicLinkFlowLoginSavesTheSessionToken(t *testing.T) {
	t.Setenv("FIZZY_NO_KEYRING", "1")
	server := fizzySessions(t, "pend-1")
	flow := ResumeMagicLinkFlow(server.URL, nil, "pend-1")
	store := NewCredentialStore(t.TempDir())
	manager := NewAuthManagerWithStore(&Config{BaseURL: server.URL}, store)

	session, err := flow.Login(context.Background(), manager, "ABC123")
	if err != nil {
		t.Fatalf("Login: %v", err)
	}
	if session.SessionToken != "st-1" {
		t.Errorf("session = %+v", session)
	}
}
