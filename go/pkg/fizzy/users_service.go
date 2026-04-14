// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// ConfirmEmailAddressChange performs the ConfirmEmailAddressChange operation on a user.
func (s *UsersService) ConfirmEmailAddressChange(ctx context.Context, userID string, emailAddressToken string) (*Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/users/%s/email_addresses/%s/confirmation.json", userID, emailAddressToken), nil)
	return resp, err
}

// CreatePushSubscription creates a push subscription.
func (s *UsersService) CreatePushSubscription(ctx context.Context, userID string, req *generated.CreatePushSubscriptionRequest) (*Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/users/%s/push_subscriptions.json", userID), req)
	return resp, err
}

// CreateUserDataExport creates a user data export.
func (s *UsersService) CreateUserDataExport(ctx context.Context, userID string) (*generated.DataExport, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/users/%s/data_exports.json", userID), nil)
	if err != nil {
		return nil, nil, err
	}
	var result generated.DataExport
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// Deactivate performs the Deactivate operation on a user.
func (s *UsersService) Deactivate(ctx context.Context, userID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/users/%s", userID))
}

// DeletePushSubscription deletes a push subscription.
func (s *UsersService) DeletePushSubscription(ctx context.Context, userID string, pushSubscriptionID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/users/%s/push_subscriptions/%s", userID, pushSubscriptionID))
}

// DeleteAvatar deletes an avatar.
func (s *UsersService) DeleteAvatar(ctx context.Context, userID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/users/%s/avatar", userID))
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

// GetUserDataExport returns a user data export.
func (s *UsersService) GetUserDataExport(ctx context.Context, userID string, exportID string) (*generated.DataExport, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/users/%s/data_exports/%s", userID, exportID))
	if err != nil {
		return nil, nil, err
	}
	var result generated.DataExport
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

// RequestEmailAddressChange performs the RequestEmailAddressChange operation on a user.
func (s *UsersService) RequestEmailAddressChange(ctx context.Context, userID string, req *generated.RequestEmailAddressChangeRequest) (*Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/users/%s/email_addresses.json", userID), req)
	return resp, err
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

// UpdateRole updates a role.
func (s *UsersService) UpdateRole(ctx context.Context, userID string, req *generated.UpdateUserRoleRequest) (*Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/users/%s/role.json", userID), req)
	return resp, err
}
