package fizzy

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// List returns cards. The path can include query params (board_ids, terms, page, etc.).
func (s *CardsService) List(ctx context.Context, path string) (json.RawMessage, *Response, error) {
	if path == "" {
		path = "/cards.json"
	}
	resp, err := s.client.Get(ctx, path)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// ListAll returns all cards across all pages for the given path.
func (s *CardsService) ListAll(ctx context.Context, path string) ([]json.RawMessage, error) {
	if path == "" {
		path = "/cards.json"
	}
	return s.client.GetAll(ctx, path)
}

// Get returns a single card by number.
func (s *CardsService) Get(ctx context.Context, cardNumber string) (*generated.Card, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/cards/%s.json", cardNumber))
	if err != nil {
		return nil, nil, err
	}
	var card generated.Card
	if err := resp.UnmarshalData(&card); err != nil {
		return nil, resp, err
	}
	return &card, resp, nil
}

// GetRaw returns a single card as raw JSON.
func (s *CardsService) GetRaw(ctx context.Context, cardNumber string) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/cards/%s.json", cardNumber))
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Create creates a new card.
func (s *CardsService) Create(ctx context.Context, req *generated.CreateCardRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, "/cards.json", req)
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

// Update updates a card.
func (s *CardsService) Update(ctx context.Context, cardNumber string, req *generated.UpdateCardRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/cards/%s.json", cardNumber), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Delete deletes a card.
func (s *CardsService) Delete(ctx context.Context, cardNumber string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s.json", cardNumber))
}

// Close closes a card.
func (s *CardsService) Close(ctx context.Context, cardNumber string) (*Response, error) {
	_, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/closure.json", cardNumber), nil)
	return nil, err
}

// Reopen reopens a closed card.
func (s *CardsService) Reopen(ctx context.Context, cardNumber string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/closure.json", cardNumber))
}

// Postpone postpones a card (moves to Not Now).
func (s *CardsService) Postpone(ctx context.Context, cardNumber string) (*Response, error) {
	_, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/not_now.json", cardNumber), nil)
	return nil, err
}

// Move moves a card to a different board.
func (s *CardsService) Move(ctx context.Context, cardNumber string, req *generated.MoveCardRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/cards/%s/board.json", cardNumber), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Assign toggles a user's assignment on a card.
func (s *CardsService) Assign(ctx context.Context, cardNumber string, req *generated.AssignCardRequest) (*Response, error) {
	_, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/assignments.json", cardNumber), req)
	return nil, err
}

// SelfAssign assigns the authenticated user to a card.
func (s *CardsService) SelfAssign(ctx context.Context, cardNumber string) (*Response, error) {
	_, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/self_assignment.json", cardNumber), nil)
	return nil, err
}

// TagCard adds a tag to a card.
func (s *CardsService) Tag(ctx context.Context, cardNumber string, req *generated.TagCardRequest) (*Response, error) {
	_, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/taggings.json", cardNumber), req)
	return nil, err
}

// Watch subscribes to a card.
func (s *CardsService) Watch(ctx context.Context, cardNumber string) (*Response, error) {
	_, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/watch.json", cardNumber), nil)
	return nil, err
}

// Unwatch unsubscribes from a card.
func (s *CardsService) Unwatch(ctx context.Context, cardNumber string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/watch.json", cardNumber))
}

// Gold marks a card as golden.
func (s *CardsService) Gold(ctx context.Context, cardNumber string) (*Response, error) {
	_, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/goldness.json", cardNumber), nil)
	return nil, err
}

// Ungold removes golden status from a card.
func (s *CardsService) Ungold(ctx context.Context, cardNumber string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/goldness.json", cardNumber))
}

// PinCard pins a card.
func (s *CardsService) Pin(ctx context.Context, cardNumber string) (*Response, error) {
	_, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/pin.json", cardNumber), nil)
	return nil, err
}

// UnpinCard unpins a card.
func (s *CardsService) Unpin(ctx context.Context, cardNumber string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/pin.json", cardNumber))
}

// DeleteImage removes the image from a card.
func (s *CardsService) DeleteImage(ctx context.Context, cardNumber string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/image.json", cardNumber))
}

// Triage triages a card to a column.
func (s *CardsService) Triage(ctx context.Context, cardNumber string, req *generated.TriageCardRequest) (*Response, error) {
	_, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/triage.json", cardNumber), req)
	return nil, err
}

// UnTriage removes a card from triage (moves to Not Now).
func (s *CardsService) UnTriage(ctx context.Context, cardNumber string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/triage.json", cardNumber))
}
