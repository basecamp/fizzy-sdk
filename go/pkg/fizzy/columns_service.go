// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Create creates a column.
func (s *ColumnsService) Create(ctx context.Context, boardID string, req *generated.CreateColumnRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/boards/%s/columns.json", boardID), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Get returns a column.
func (s *ColumnsService) Get(ctx context.Context, boardID string, columnID string) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/boards/%s/columns/%s", boardID, columnID))
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// List returns columns.
func (s *ColumnsService) List(ctx context.Context, boardID string) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/boards/%s/columns.json", boardID))
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Update updates a column.
func (s *ColumnsService) Update(ctx context.Context, boardID string, columnID string, req *generated.UpdateColumnRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/boards/%s/columns/%s", boardID, columnID), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}
