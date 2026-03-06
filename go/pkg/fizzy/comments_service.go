package fizzy

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// List returns comments for a card.
func (s *CommentsService) List(ctx context.Context, cardNumber string, path string) (json.RawMessage, *Response, error) {
	if path == "" {
		path = fmt.Sprintf("/cards/%s/comments.json", cardNumber)
	}
	resp, err := s.client.Get(ctx, path)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// ListAll returns all comments for a card across all pages.
func (s *CommentsService) ListAll(ctx context.Context, cardNumber string) ([]json.RawMessage, error) {
	return s.client.GetAll(ctx, fmt.Sprintf("/cards/%s/comments.json", cardNumber))
}

// Get returns a single comment.
func (s *CommentsService) Get(ctx context.Context, cardNumber, commentID string) (*generated.Comment, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/cards/%s/comments/%s.json", cardNumber, commentID))
	if err != nil {
		return nil, nil, err
	}
	var comment generated.Comment
	if err := resp.UnmarshalData(&comment); err != nil {
		return nil, resp, err
	}
	return &comment, resp, nil
}

// Create creates a new comment on a card.
func (s *CommentsService) Create(ctx context.Context, cardNumber string, req *generated.CreateCommentRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/comments.json", cardNumber), req)
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

// Update updates a comment.
func (s *CommentsService) Update(ctx context.Context, cardNumber, commentID string, req *generated.UpdateCommentRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/cards/%s/comments/%s.json", cardNumber, commentID), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Delete deletes a comment.
func (s *CommentsService) Delete(ctx context.Context, cardNumber, commentID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/comments/%s.json", cardNumber, commentID))
}
