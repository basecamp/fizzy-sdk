// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Assign performs the Assign operation on a card.
func (s *CardsService) Assign(ctx context.Context, cardNumber string, req *generated.AssignCardRequest) (*Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/assignments.json", cardNumber), req)
	return resp, err
}

// Close performs the Close operation on a card.
func (s *CardsService) Close(ctx context.Context, cardNumber string) (*Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/closure.json", cardNumber), nil)
	return resp, err
}

// Create creates a card.
func (s *CardsService) Create(ctx context.Context, req *generated.CreateCardRequest) (*generated.Card, *Response, error) {
	resp, err := s.client.Post(ctx, "/cards.json", req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.Card
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// Delete deletes a card.
func (s *CardsService) Delete(ctx context.Context, cardNumber string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s", cardNumber))
}

// DeleteImage deletes an image.
func (s *CardsService) DeleteImage(ctx context.Context, cardNumber string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/image.json", cardNumber))
}

// Get returns a card.
func (s *CardsService) Get(ctx context.Context, cardNumber string) (*generated.Card, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/cards/%s", cardNumber))
	if err != nil {
		return nil, nil, err
	}
	var result generated.Card
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// Gold performs the Gold operation on a card.
func (s *CardsService) Gold(ctx context.Context, cardNumber string) (*Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/goldness.json", cardNumber), nil)
	return resp, err
}

// List returns cards.
func (s *CardsService) List(ctx context.Context, path string) ([]generated.Card, *Response, error) {
	if path == "" {
		path = "/cards.json"
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

// Move performs the Move operation on a card.
func (s *CardsService) Move(ctx context.Context, cardNumber string, req *generated.MoveCardRequest) (*generated.Card, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/cards/%s/board.json", cardNumber), req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.Card
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// Pin performs the Pin operation on a card.
func (s *CardsService) Pin(ctx context.Context, cardNumber string) (*Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/pin.json", cardNumber), nil)
	return resp, err
}

// Postpone performs the Postpone operation on a card.
func (s *CardsService) Postpone(ctx context.Context, cardNumber string) (*Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/not_now.json", cardNumber), nil)
	return resp, err
}

// Reopen performs the Reopen operation on a card.
func (s *CardsService) Reopen(ctx context.Context, cardNumber string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/closure.json", cardNumber))
}

// SelfAssign performs the SelfAssign operation on a card.
func (s *CardsService) SelfAssign(ctx context.Context, cardNumber string) (*Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/self_assignment.json", cardNumber), nil)
	return resp, err
}

// Tag performs the Tag operation on a card.
func (s *CardsService) Tag(ctx context.Context, cardNumber string, req *generated.TagCardRequest) (*Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/taggings.json", cardNumber), req)
	return resp, err
}

// Triage performs the Triage operation on a card.
func (s *CardsService) Triage(ctx context.Context, cardNumber string, req *generated.TriageCardRequest) (*Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/triage.json", cardNumber), req)
	return resp, err
}

// UnTriage performs the UnTriage operation on a card.
func (s *CardsService) UnTriage(ctx context.Context, cardNumber string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/triage.json", cardNumber))
}

// Ungold performs the Ungold operation on a card.
func (s *CardsService) Ungold(ctx context.Context, cardNumber string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/goldness.json", cardNumber))
}

// Unpin performs the Unpin operation on a card.
func (s *CardsService) Unpin(ctx context.Context, cardNumber string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/pin.json", cardNumber))
}

// Unwatch performs the Unwatch operation on a card.
func (s *CardsService) Unwatch(ctx context.Context, cardNumber string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/watch.json", cardNumber))
}

// Update updates a card.
func (s *CardsService) Update(ctx context.Context, cardNumber string, req *generated.UpdateCardRequest) (*generated.Card, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/cards/%s", cardNumber), req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.Card
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// Watch performs the Watch operation on a card.
func (s *CardsService) Watch(ctx context.Context, cardNumber string) (*Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/watch.json", cardNumber), nil)
	return resp, err
}
