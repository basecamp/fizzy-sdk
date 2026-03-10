// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Create creates a board.
func (s *BoardsService) Create(ctx context.Context, req *generated.CreateBoardRequest) (*generated.Board, *Response, error) {
	resp, err := s.client.Post(ctx, "/boards.json", req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.Board
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// Delete deletes a board.
func (s *BoardsService) Delete(ctx context.Context, boardID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/boards/%s", boardID))
}

// Get returns a board.
func (s *BoardsService) Get(ctx context.Context, boardID string) (*generated.Board, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/boards/%s", boardID))
	if err != nil {
		return nil, nil, err
	}
	var result generated.Board
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// List returns boards.
func (s *BoardsService) List(ctx context.Context, path string) ([]generated.Board, *Response, error) {
	if path == "" {
		path = "/boards.json"
	}
	resp, err := s.client.Get(ctx, path)
	if err != nil {
		return nil, nil, err
	}
	var result []generated.Board
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return result, resp, nil
}

// ListClosed returns closed cards.
func (s *BoardsService) ListClosed(ctx context.Context, boardID string, path string) ([]generated.Card, *Response, error) {
	if path == "" {
		path = fmt.Sprintf("/boards/%s/columns/closed.json", boardID)
	}
	resp, err := s.client.Get(ctx, path)
	if err != nil {
		return nil, nil, err
	}
	var result []generated.Card
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return result, resp, nil
}

// ListPostponed returns postponed cards.
func (s *BoardsService) ListPostponed(ctx context.Context, boardID string, path string) ([]generated.Card, *Response, error) {
	if path == "" {
		path = fmt.Sprintf("/boards/%s/columns/not_now.json", boardID)
	}
	resp, err := s.client.Get(ctx, path)
	if err != nil {
		return nil, nil, err
	}
	var result []generated.Card
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return result, resp, nil
}

// ListStream returns streams.
func (s *BoardsService) ListStream(ctx context.Context, boardID string, path string) ([]generated.Card, *Response, error) {
	if path == "" {
		path = fmt.Sprintf("/boards/%s/columns/stream.json", boardID)
	}
	resp, err := s.client.Get(ctx, path)
	if err != nil {
		return nil, nil, err
	}
	var result []generated.Card
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return result, resp, nil
}

// Publish performs the Publish operation on a board.
func (s *BoardsService) Publish(ctx context.Context, boardID string) (*Response, error) {
	resp, err := s.client.Post(WithIdempotent(ctx), fmt.Sprintf("/boards/%s/publication.json", boardID), nil)
	return resp, err
}

// Unpublish performs the Unpublish operation on a board.
func (s *BoardsService) Unpublish(ctx context.Context, boardID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/boards/%s/publication.json", boardID))
}

// Update updates a board.
func (s *BoardsService) Update(ctx context.Context, boardID string, req *generated.UpdateBoardRequest) (*generated.Board, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/boards/%s", boardID), req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.Board
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// UpdateEntropy updates an entropy.
func (s *BoardsService) UpdateEntropy(ctx context.Context, boardID string, req *generated.UpdateBoardEntropyRequest) (*generated.Board, *Response, error) {
	resp, err := s.client.Put(ctx, fmt.Sprintf("/boards/%s/entropy.json", boardID), req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.Board
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// UpdateInvolvement updates an involvement.
func (s *BoardsService) UpdateInvolvement(ctx context.Context, boardID string, req *generated.UpdateBoardInvolvementRequest) (*Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/boards/%s/involvement.json", boardID), req)
	return resp, err
}
