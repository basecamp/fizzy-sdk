package fizzy

import (
	"context"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"sync"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// PendingAuthenticationCookie is the cookie a pending sign-in is carried in between
// creating the session and redeeming the code.
const PendingAuthenticationCookie = "pending_authentication_token"

// MagicLinkFlow signs in without a password. Fizzy emails a code to an address and,
// once the person types it back, answers a session token for CookieAuth.
//
// The two steps are one exchange as far as Fizzy is concerned: CreateSession answers a
// pending authentication token, and RedeemMagicLink has to send it back as the
// pending_authentication_token cookie or the code is refused. The flow keeps the token
// between the calls, and hands it out (PendingToken) for a caller that finishes in
// another process — a CLI that prompts for the code on its next run — which picks it
// back up with ResumeMagicLinkFlow.
//
// Both steps go out through the generated SessionsService routes (/session.json and
// /session/magic_link.json) and their generated request and response types.
type MagicLinkFlow struct {
	client *Client

	mu      sync.Mutex
	pending string
}

// NewMagicLinkFlow creates a flow against baseURL. A non-nil httpClient lends its
// Transport and Timeout; the flow sends no credentials, since there are none yet. Like
// NewClient, it panics on a base URL that is not HTTPS (localhost aside).
func NewMagicLinkFlow(baseURL string, httpClient *http.Client) *MagicLinkFlow {
	var opts []ClientOption
	if httpClient != nil {
		if httpClient.Transport != nil {
			opts = append(opts, WithTransport(httpClient.Transport))
		}
		if httpClient.Timeout > 0 {
			opts = append(opts, WithTimeout(httpClient.Timeout))
		}
	}
	opts = append(opts, WithAuthStrategy(pendingCookieAuth{}))
	return &MagicLinkFlow{
		client: NewClient(&Config{BaseURL: NormalizeBaseURL(baseURL)}, nil, opts...),
	}
}

// ResumeMagicLinkFlow creates a flow that picks up where another left off, with the
// pending token that one handed out through PendingToken.
func ResumeMagicLinkFlow(baseURL string, httpClient *http.Client, pendingToken string) *MagicLinkFlow {
	flow := NewMagicLinkFlow(baseURL, httpClient)
	flow.pending = pendingToken
	return flow
}

// CreateSession asks Fizzy to email a sign-in code to emailAddress, and keeps the
// pending token the answer carries for RedeemMagicLink.
func (f *MagicLinkFlow) CreateSession(ctx context.Context, emailAddress string) (*generated.PendingAuthentication, error) {
	pending, _, err := f.client.Sessions().Create(ctx, &generated.CreateSessionRequest{EmailAddress: emailAddress})
	if err != nil {
		return nil, err
	}
	f.mu.Lock()
	f.pending = pending.PendingAuthenticationToken
	f.mu.Unlock()
	return pending, nil
}

// PendingToken is the token a pending sign-in is waiting on, or "" when none is, for a
// caller that finishes the flow in another process.
func (f *MagicLinkFlow) PendingToken() string {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.pending
}

// RedeemMagicLink sends the code from the email back with the pending token, and
// answers the session Fizzy signed in. Without a pending token — no CreateSession
// before it, and none given to ResumeMagicLinkFlow — there is nothing to redeem against.
func (f *MagicLinkFlow) RedeemMagicLink(ctx context.Context, code string) (*generated.SessionAuthorization, error) {
	pending := f.PendingToken()
	if pending == "" {
		return nil, &Error{
			Code:    CodeUsage,
			Message: "no sign-in is pending",
			Hint:    "call CreateSession first, or resume with the pending token",
		}
	}
	ctx = context.WithValue(ctx, pendingTokenKey{}, pending)
	session, _, err := f.client.Sessions().RedeemMagicLink(ctx, &generated.RedeemMagicLinkRequest{Code: code})
	if err != nil {
		return nil, err
	}
	f.mu.Lock()
	f.pending = ""
	f.mu.Unlock()
	return session, nil
}

// Login redeems the code and stores the session token Fizzy answers. When the answer
// says RequiresSignupCompletion, the caller completes the signup next
// (SessionsService.CompleteSignup) with that session.
func (f *MagicLinkFlow) Login(ctx context.Context, authManager *AuthManager, code string) (*generated.SessionAuthorization, error) {
	session, err := f.RedeemMagicLink(ctx, code)
	if err != nil {
		return nil, err
	}
	if err := authManager.SaveSessionToken(session.SessionToken); err != nil {
		return nil, fmt.Errorf("failed to save session token: %w", err)
	}
	return session, nil
}

type pendingTokenKey struct{}

// pendingCookieAuth sends no credentials, except the pending token as the
// pending_authentication_token cookie on the redeem it is handed to.
type pendingCookieAuth struct{}

func (pendingCookieAuth) Authenticate(ctx context.Context, req *http.Request) error {
	if token, ok := ctx.Value(pendingTokenKey{}).(string); ok && token != "" {
		req.Header.Add("Cookie", PendingAuthenticationCookie+"="+escapeCookieValue(token))
	}
	return nil
}

// escapeCookieValue percent-encodes everything but ASCII letters, digits and -_.~, as
// Rack unescapes a cookie value; a raw token can carry characters a cookie cannot.
func escapeCookieValue(value string) string {
	return strings.ReplaceAll(url.QueryEscape(value), "+", "%20")
}
