// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Deactivate performs the Deactivate operation on a user.
func (s *UsersService) Deactivate(ctx context.Context, userID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/users/%s", userID))
}

// Get returns a user.
func (s *UsersService) Get(ctx context.Context, userID string) (*generated.User, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/users/%s", userID))
	if err != nil {
		return nil, nil, err
	}
	var result generated.User
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// List returns users.
func (s *UsersService) List(ctx context.Context, path string) ([]generated.User, *Response, error) {
	if path == "" {
		path = "/users.json"
	}
	resp, err := s.client.Get(ctx, path)
	if err != nil {
		return nil, nil, err
	}
	var result []generated.User
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return result, resp, nil
}

// Update updates a user.
func (s *UsersService) Update(ctx context.Context, userID string, req *generated.UpdateUserRequest) (*generated.User, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/users/%s", userID), req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.User
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}
