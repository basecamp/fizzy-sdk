// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// CompleteSignup performs the CompleteSignup operation on a session.
func (s *SessionsService) CompleteSignup(ctx context.Context, req *generated.CompleteSignupRequest) (*generated.User, *Response, error) {
	resp, err := s.client.Post(ctx, "/signup/completion.json", req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.User
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// Create creates a session.
func (s *SessionsService) Create(ctx context.Context, req *generated.CreateSessionRequest) (*generated.PendingAuthentication, *Response, error) {
	resp, err := s.client.Post(ctx, "/session.json", req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.PendingAuthentication
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// Destroy performs the Destroy operation on a session.
func (s *SessionsService) Destroy(ctx context.Context) (*Response, error) {
	return s.client.Delete(WithNoRetry(ctx), "/session.json")
}

// RedeemMagicLink performs the RedeemMagicLink operation on a session.
func (s *SessionsService) RedeemMagicLink(ctx context.Context, req *generated.RedeemMagicLinkRequest) (*generated.SessionAuthorization, *Response, error) {
	resp, err := s.client.Post(ctx, "/session/magic_link.json", req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.SessionAuthorization
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}
