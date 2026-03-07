// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Create creates a board.
func (s *BoardsService) Create(ctx context.Context, req *generated.CreateBoardRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, "/boards.json", req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Delete deletes a board.
func (s *BoardsService) Delete(ctx context.Context, boardID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/boards/%s.json", boardID))
}

// Get returns a board.
func (s *BoardsService) Get(ctx context.Context, boardID string) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/boards/%s.json", boardID))
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// List returns boards.
func (s *BoardsService) List(ctx context.Context, path string) (json.RawMessage, *Response, error) {
	if path == "" {
		path = "/boards.json"
	}
	resp, err := s.client.Get(ctx, path)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Update updates a board.
func (s *BoardsService) Update(ctx context.Context, boardID string, req *generated.UpdateBoardRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/boards/%s.json", boardID), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}
