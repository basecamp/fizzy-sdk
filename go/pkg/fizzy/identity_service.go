// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"fmt"

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

// UpdateTimezone updates a timezone.
func (s *IdentityService) UpdateTimezone(ctx context.Context, accountID string, req *generated.UpdateMyTimezoneRequest) (*Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/%s/my/timezone.json", accountID), req)
	return resp, err
}
