package fizzy

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Get returns a single step.
func (s *StepsService) Get(ctx context.Context, cardNumber, stepID string) (*generated.Step, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/cards/%s/steps/%s.json", cardNumber, stepID))
	if err != nil {
		return nil, nil, err
	}
	var step generated.Step
	if err := resp.UnmarshalData(&step); err != nil {
		return nil, resp, err
	}
	return &step, resp, nil
}

// Create creates a new step on a card.
func (s *StepsService) Create(ctx context.Context, cardNumber string, req *generated.CreateStepRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/steps.json", cardNumber), req)
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

// Update updates a step.
func (s *StepsService) Update(ctx context.Context, cardNumber, stepID string, req *generated.UpdateStepRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/cards/%s/steps/%s.json", cardNumber, stepID), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Delete deletes a step.
func (s *StepsService) Delete(ctx context.Context, cardNumber, stepID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/steps/%s.json", cardNumber, stepID))
}
