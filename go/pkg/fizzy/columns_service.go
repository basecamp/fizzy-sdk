package fizzy

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// List returns columns for a board.
func (s *ColumnsService) List(ctx context.Context, boardID string) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/boards/%s/columns.json", boardID))
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Get returns a single column.
func (s *ColumnsService) Get(ctx context.Context, boardID, columnID string) (*generated.Column, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/boards/%s/columns/%s.json", boardID, columnID))
	if err != nil {
		return nil, nil, err
	}
	var col generated.Column
	if err := resp.UnmarshalData(&col); err != nil {
		return nil, resp, err
	}
	return &col, resp, nil
}

// Create creates a new column on a board.
func (s *ColumnsService) Create(ctx context.Context, boardID string, req *generated.CreateColumnRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/boards/%s/columns.json", boardID), req)
	if err != nil {
		return nil, nil, err
	}
	if loc := resp.Headers.Get("Location"); loc != "" {
		followResp, err := s.client.parent.Get(ctx, loc)
		if err != nil {
			return nil, resp, err
		}
		return followResp.Data, &Response{
			Data:       followResp.Data,
			StatusCode: followResp.StatusCode,
			Headers:    resp.Headers,
		}, nil
	}
	return resp.Data, resp, nil
}

// Update updates a column.
func (s *ColumnsService) Update(ctx context.Context, boardID, columnID string, req *generated.UpdateColumnRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/boards/%s/columns/%s.json", boardID, columnID), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}
