// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Create creates an access token.
func (s *AccessTokensService) Create(ctx context.Context, req *generated.CreateAccessTokenRequest) (*generated.AccessToken, *Response, error) {
	resp, err := s.client.Post(ctx, "/my/access_tokens.json", req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.AccessToken
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// Delete deletes an access token.
func (s *AccessTokensService) Delete(ctx context.Context, accessTokenID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/my/access_tokens/%s", accessTokenID))
}

// List returns access tokens.
func (s *AccessTokensService) List(ctx context.Context) ([]generated.AccessToken, *Response, error) {
	resp, err := s.client.Get(ctx, "/my/access_tokens.json")
	if err != nil {
		return nil, nil, err
	}
	var result []generated.AccessToken
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return result, resp, nil
}
