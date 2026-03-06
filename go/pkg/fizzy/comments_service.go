// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Create creates a comment.
func (s *CommentsService) Create(ctx context.Context, cardNumber string, req *generated.CreateCommentRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/comments.json", cardNumber), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Delete deletes a comment.
func (s *CommentsService) Delete(ctx context.Context, cardNumber string, commentID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/comments/%s", cardNumber, commentID))
}

// Get returns a comment.
func (s *CommentsService) Get(ctx context.Context, cardNumber string, commentID string) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/cards/%s/comments/%s", cardNumber, commentID))
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// List returns comments.
func (s *CommentsService) List(ctx context.Context, path string) (json.RawMessage, *Response, error) {
	if path == "" {
		path = "/cards/%s/comments.json"
	}
	resp, err := s.client.Get(ctx, path)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Update updates a comment.
func (s *CommentsService) Update(ctx context.Context, cardNumber string, commentID string, req *generated.UpdateCommentRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/cards/%s/comments/%s", cardNumber, commentID), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}
