// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Create creates a column.
func (s *ColumnsService) Create(ctx context.Context, boardID string, req *generated.CreateColumnRequest) (*generated.Column, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/boards/%s/columns.json", boardID), req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.Column
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// Delete deletes a column.
func (s *ColumnsService) Delete(ctx context.Context, boardID string, columnID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/boards/%s/columns/%s", boardID, columnID))
}

// Get returns a column.
func (s *ColumnsService) Get(ctx context.Context, boardID string, columnID string) (*generated.Column, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/boards/%s/columns/%s", boardID, columnID))
	if err != nil {
		return nil, nil, err
	}
	var result generated.Column
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// List returns columns.
func (s *ColumnsService) List(ctx context.Context, boardID string) ([]generated.Column, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/boards/%s/columns.json", boardID))
	if err != nil {
		return nil, nil, err
	}
	var result []generated.Column
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return result, resp, nil
}

// Update updates a column.
func (s *ColumnsService) Update(ctx context.Context, boardID string, columnID string, req *generated.UpdateColumnRequest) (*generated.Column, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/boards/%s/columns/%s", boardID, columnID), req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.Column
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}
