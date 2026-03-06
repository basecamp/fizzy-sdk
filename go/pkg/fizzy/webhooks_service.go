// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Activate performs the Activate operation on a webhook.
func (s *WebhooksService) Activate(ctx context.Context, boardID string, webhookID string) (*Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/boards/%s/webhooks/%s/activation.json", boardID, webhookID), nil)
	return resp, err
}

// Create creates a webhook.
func (s *WebhooksService) Create(ctx context.Context, boardID string, req *generated.CreateWebhookRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/boards/%s/webhooks.json", boardID), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Delete deletes a webhook.
func (s *WebhooksService) Delete(ctx context.Context, boardID string, webhookID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/boards/%s/webhooks/%s", boardID, webhookID))
}

// Get returns a webhook.
func (s *WebhooksService) Get(ctx context.Context, boardID string, webhookID string) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/boards/%s/webhooks/%s", boardID, webhookID))
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// List returns webhooks.
func (s *WebhooksService) List(ctx context.Context, boardID string) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/boards/%s/webhooks.json", boardID))
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Update updates a webhook.
func (s *WebhooksService) Update(ctx context.Context, boardID string, webhookID string, req *generated.UpdateWebhookRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/boards/%s/webhooks/%s", boardID, webhookID), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}
