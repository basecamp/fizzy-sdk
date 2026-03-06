// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"encoding/json"
)

// GetMyIdentity returns a identity.
func (s *IdentityService) GetMyIdentity(ctx context.Context) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, "/my/identity.json")
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}
