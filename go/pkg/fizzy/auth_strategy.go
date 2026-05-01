package fizzy

import (
	"context"
	"net/http"
)

// AuthStrategy controls how authentication is applied to HTTP requests.
// The default strategy is BearerAuth, which uses a TokenProvider to set
// the Authorization header with a Bearer token.
//
// Custom strategies can implement alternative auth schemes such as
// cookie-based auth or API keys.
type AuthStrategy interface {
	// Authenticate applies authentication to the given HTTP request.
	Authenticate(ctx context.Context, req *http.Request) error
}

// BearerAuth implements AuthStrategy using Bearer tokens.
// This is the default authentication strategy.
type BearerAuth struct {
	TokenProvider TokenProvider
}

// Authenticate sets the Authorization header with a Bearer token.
func (b *BearerAuth) Authenticate(ctx context.Context, req *http.Request) error {
	token, err := b.TokenProvider.AccessToken(ctx)
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	return nil
}

// CookieAuth implements AuthStrategy using session cookies.
// Sets Cookie: session_token=<value> header for session-based auth.
type CookieAuth struct {
	TokenProvider TokenProvider
}

// Authenticate sets the Cookie header with a session token.
func (c *CookieAuth) Authenticate(ctx context.Context, req *http.Request) error {
	token, err := c.TokenProvider.AccessToken(ctx)
	if err != nil {
		return err
	}
	// Per RFC 6265 §5.4 and net/http docs, AddCookie only transmits name=value;
	// Secure/HttpOnly/SameSite are Set-Cookie response attributes and are not
	// written into outgoing Cookie request headers. Setting them here would be
	// dead code, so suppress G124 instead.
	req.AddCookie(&http.Cookie{Name: "session_token", Value: token}) // #nosec G124 -- false positive: outgoing request cookie only sends name=value
	return nil
}
