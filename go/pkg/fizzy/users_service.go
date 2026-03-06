// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Deactivate performs the Deactivate operation on a user.
func (s *UsersService) Deactivate(ctx context.Context, userID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/users/%s", userID))
}

// Get returns a user.
func (s *UsersService) Get(ctx context.Context, userID string) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/users/%s", userID))
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// List returns users.
func (s *UsersService) List(ctx context.Context) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, "/users.json")
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Update updates a user.
func (s *UsersService) Update(ctx context.Context, userID string, req *generated.UpdateUserRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/users/%s", userID), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}
