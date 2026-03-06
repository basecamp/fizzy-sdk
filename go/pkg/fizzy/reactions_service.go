package fizzy

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// ListCard returns reactions for a card.
func (s *ReactionsService) ListCard(ctx context.Context, cardNumber string) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/cards/%s/reactions.json", cardNumber))
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// CreateCard creates a reaction on a card.
func (s *ReactionsService) CreateCard(ctx context.Context, cardNumber string, req *generated.CreateReactionRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/reactions.json", cardNumber), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// DeleteCard deletes a reaction from a card.
func (s *ReactionsService) DeleteCard(ctx context.Context, cardNumber, reactionID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/reactions/%s.json", cardNumber, reactionID))
}

// ListComment returns reactions for a comment.
func (s *ReactionsService) ListComment(ctx context.Context, cardNumber, commentID string) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/cards/%s/comments/%s/reactions.json", cardNumber, commentID))
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// CreateComment creates a reaction on a comment.
func (s *ReactionsService) CreateComment(ctx context.Context, cardNumber, commentID string, req *generated.CreateReactionRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/comments/%s/reactions.json", cardNumber, commentID), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// DeleteComment deletes a reaction from a comment.
func (s *ReactionsService) DeleteComment(ctx context.Context, cardNumber, commentID, reactionID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/comments/%s/reactions/%s.json", cardNumber, commentID, reactionID))
}
