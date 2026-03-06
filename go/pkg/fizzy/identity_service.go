package fizzy

import (
	"context"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// GetMyIdentity returns the authenticated user's identity.
func (s *IdentityService) GetMyIdentity(ctx context.Context) (*generated.Identity, *Response, error) {
	resp, err := s.client.Get(ctx, "/my/identity.json")
	if err != nil {
		return nil, nil, err
	}
	var identity generated.Identity
	if err := resp.UnmarshalData(&identity); err != nil {
		return nil, resp, err
	}
	return &identity, resp, nil
}
