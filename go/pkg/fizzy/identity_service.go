// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// GetMyIdentity returns an identity.
func (s *IdentityService) GetMyIdentity(ctx context.Context) (*generated.Identity, *Response, error) {
	resp, err := s.client.Get(ctx, "/my/identity.json")
	if err != nil {
		return nil, nil, err
	}
	var result generated.Identity
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// UpdateMyTimezone updates my timezone.
func (s *IdentityService) UpdateMyTimezone(ctx context.Context, accountID string, req *generated.UpdateMyTimezoneRequest) (*Response, error) {
	path, ok := URLPathByOperation("UpdateMyTimezone", map[string]string{"accountId": accountID})
	if !ok {
		return nil, ErrUsage("missing generated route for UpdateMyTimezone")
	}
	resp, err := s.client.Patch(ctx, path, req)
	return resp, err
}
