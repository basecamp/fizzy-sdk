// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Create creates a comment.
func (s *CommentsService) Create(ctx context.Context, cardNumber string, req *generated.CreateCommentRequest) (*generated.Comment, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/comments.json", cardNumber), req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.Comment
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// Delete deletes a comment.
func (s *CommentsService) Delete(ctx context.Context, cardNumber string, commentID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/comments/%s", cardNumber, commentID))
}

// Get returns a comment.
func (s *CommentsService) Get(ctx context.Context, cardNumber string, commentID string) (*generated.Comment, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/cards/%s/comments/%s", cardNumber, commentID))
	if err != nil {
		return nil, nil, err
	}
	var result generated.Comment
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// List returns comments.
func (s *CommentsService) List(ctx context.Context, cardNumber string, path string) ([]generated.Comment, *Response, error) {
	if path == "" {
		path = fmt.Sprintf("/cards/%s/comments.json", cardNumber)
	}
	resp, err := s.client.Get(ctx, path)
	if err != nil {
		return nil, nil, err
	}
	var result []generated.Comment
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return result, resp, nil
}

// Update updates a comment.
func (s *CommentsService) Update(ctx context.Context, cardNumber string, commentID string, req *generated.UpdateCommentRequest) (*generated.Comment, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/cards/%s/comments/%s", cardNumber, commentID), req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.Comment
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}
