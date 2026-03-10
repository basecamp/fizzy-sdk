// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// CreateExport creates an export.
func (s *AccountService) CreateExport(ctx context.Context) (*generated.AccountExport, *Response, error) {
	resp, err := s.client.Post(ctx, "/account/exports.json", nil)
	if err != nil {
		return nil, nil, err
	}
	var result generated.AccountExport
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// GetExport returns an export.
func (s *AccountService) GetExport(ctx context.Context, exportID string) (*generated.AccountExport, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/account/exports/%s", exportID))
	if err != nil {
		return nil, nil, err
	}
	var result generated.AccountExport
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// GetSettings returns settings.
func (s *AccountService) GetSettings(ctx context.Context) (*generated.AccountSettings, *Response, error) {
	resp, err := s.client.Get(ctx, "/account/settings.json")
	if err != nil {
		return nil, nil, err
	}
	var result generated.AccountSettings
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// GetJoinCode returns a join code.
func (s *AccountService) GetJoinCode(ctx context.Context) (*generated.JoinCode, *Response, error) {
	resp, err := s.client.Get(ctx, "/account/join_code.json")
	if err != nil {
		return nil, nil, err
	}
	var result generated.JoinCode
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// ResetJoinCode performs the ResetJoinCode operation on an account.
func (s *AccountService) ResetJoinCode(ctx context.Context) (*Response, error) {
	return s.client.Delete(ctx, "/account/join_code.json")
}

// UpdateEntropy updates an entropy.
func (s *AccountService) UpdateEntropy(ctx context.Context, req *generated.UpdateAccountEntropyRequest) (*generated.AccountSettings, *Response, error) {
	resp, err := s.client.Put(ctx, "/account/entropy.json", req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.AccountSettings
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// UpdateSettings updates settings.
func (s *AccountService) UpdateSettings(ctx context.Context, req *generated.UpdateAccountSettingsRequest) (*Response, error) {
	resp, err := s.client.Patch(ctx, "/account/settings.json", req)
	return resp, err
}

// UpdateJoinCode updates a join code.
func (s *AccountService) UpdateJoinCode(ctx context.Context, req *generated.UpdateJoinCodeRequest) (*Response, error) {
	resp, err := s.client.Patch(ctx, "/account/join_code.json", req)
	return resp, err
}
