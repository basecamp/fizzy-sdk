// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// CreateCard creates a reaction.
func (s *ReactionsService) CreateCard(ctx context.Context, cardNumber string, req *generated.CreateCardReactionRequest) (*generated.Reaction, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/reactions.json", cardNumber), req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.Reaction
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// CreateComment creates a reaction.
func (s *ReactionsService) CreateComment(ctx context.Context, cardNumber string, commentID string, req *generated.CreateCommentReactionRequest) (*generated.Reaction, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/comments/%s/reactions.json", cardNumber, commentID), req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.Reaction
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// DeleteCard deletes a reaction.
func (s *ReactionsService) DeleteCard(ctx context.Context, cardNumber string, reactionID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/reactions/%s", cardNumber, reactionID))
}

// DeleteComment deletes a reaction.
func (s *ReactionsService) DeleteComment(ctx context.Context, cardNumber string, commentID string, reactionID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/comments/%s/reactions/%s", cardNumber, commentID, reactionID))
}

// ListCard returns reactions.
func (s *ReactionsService) ListCard(ctx context.Context, cardNumber string) ([]generated.Reaction, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/cards/%s/reactions.json", cardNumber))
	if err != nil {
		return nil, nil, err
	}
	var result []generated.Reaction
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return result, resp, nil
}

// ListComment returns reactions.
func (s *ReactionsService) ListComment(ctx context.Context, cardNumber string, commentID string) ([]generated.Reaction, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/cards/%s/comments/%s/reactions.json", cardNumber, commentID))
	if err != nil {
		return nil, nil, err
	}
	var result []generated.Reaction
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return result, resp, nil
}
