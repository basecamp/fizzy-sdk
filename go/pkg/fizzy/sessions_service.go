package fizzy

import (
	"context"
	"encoding/json"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Create creates a session (sends magic link email).
func (s *SessionsService) Create(ctx context.Context, req *generated.CreateSessionRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, "/session.json", req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// RedeemMagicLink redeems a magic link token.
func (s *SessionsService) RedeemMagicLink(ctx context.Context, req *generated.RedeemMagicLinkRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, "/session/magic_link.json", req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Destroy destroys the current session.
func (s *SessionsService) Destroy(ctx context.Context) (*Response, error) {
	return s.client.Delete(ctx, "/session.json")
}

// CompleteSignup completes a signup after magic link authentication.
func (s *SessionsService) CompleteSignup(ctx context.Context, req *generated.CompleteSignupRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, "/signup/completion.json", req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}
