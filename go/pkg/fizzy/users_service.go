package fizzy

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// List returns users for the account.
func (s *UsersService) List(ctx context.Context) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, "/users.json")
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Get returns a single user.
func (s *UsersService) Get(ctx context.Context, userID string) (*generated.User, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/users/%s.json", userID))
	if err != nil {
		return nil, nil, err
	}
	var user generated.User
	if err := resp.UnmarshalData(&user); err != nil {
		return nil, resp, err
	}
	return &user, resp, nil
}

// Update updates a user.
func (s *UsersService) Update(ctx context.Context, userID string, req *generated.UpdateUserRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/users/%s.json", userID), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Deactivate deactivates a user.
func (s *UsersService) Deactivate(ctx context.Context, userID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/users/%s.json", userID))
}
