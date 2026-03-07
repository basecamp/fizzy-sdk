// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Create creates a step.
func (s *StepsService) Create(ctx context.Context, cardNumber string, req *generated.CreateStepRequest) (*generated.Step, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/cards/%s/steps.json", cardNumber), req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.Step
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// Delete deletes a step.
func (s *StepsService) Delete(ctx context.Context, cardNumber string, stepID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/cards/%s/steps/%s", cardNumber, stepID))
}

// Get returns a step.
func (s *StepsService) Get(ctx context.Context, cardNumber string, stepID string) (*generated.Step, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/cards/%s/steps/%s", cardNumber, stepID))
	if err != nil {
		return nil, nil, err
	}
	var result generated.Step
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// Update updates a step.
func (s *StepsService) Update(ctx context.Context, cardNumber string, stepID string, req *generated.UpdateStepRequest) (*generated.Step, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/cards/%s/steps/%s", cardNumber, stepID), req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.Step
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}
