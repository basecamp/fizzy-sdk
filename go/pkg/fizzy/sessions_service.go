// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"encoding/json"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// CompleteSignup performs the CompleteSignup operation on a session.
func (s *SessionsService) CompleteSignup(ctx context.Context, req *generated.CompleteSignupRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, "/signup/completion.json", req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Create creates a session.
func (s *SessionsService) Create(ctx context.Context, req *generated.CreateSessionRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, "/session.json", req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Destroy performs the Destroy operation on a session.
func (s *SessionsService) Destroy(ctx context.Context) (*Response, error) {
	return s.client.Delete(ctx, "/session.json")
}

// RedeemMagicLink performs the RedeemMagicLink operation on a session.
func (s *SessionsService) RedeemMagicLink(ctx context.Context, req *generated.RedeemMagicLinkRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, "/session/magic_link.json", req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}
