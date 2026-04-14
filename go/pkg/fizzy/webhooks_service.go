// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Activate performs the Activate operation on a webhook.
func (s *WebhooksService) Activate(ctx context.Context, boardID string, webhookID string) (*Response, error) {
	resp, err := s.client.Post(WithIdempotent(ctx), fmt.Sprintf("/boards/%s/webhooks/%s/activation.json", boardID, webhookID), nil)
	return resp, err
}

// Create creates a webhook.
func (s *WebhooksService) Create(ctx context.Context, boardID string, req *generated.CreateWebhookRequest) (*generated.Webhook, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/boards/%s/webhooks.json", boardID), req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.Webhook
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// Delete deletes a webhook.
func (s *WebhooksService) Delete(ctx context.Context, boardID string, webhookID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/boards/%s/webhooks/%s", boardID, webhookID))
}

// Get returns a webhook.
func (s *WebhooksService) Get(ctx context.Context, boardID string, webhookID string) (*generated.Webhook, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/boards/%s/webhooks/%s", boardID, webhookID))
	if err != nil {
		return nil, nil, err
	}
	var result generated.Webhook
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}

// ListWebhookDeliveries returns webhook deliveries.
func (s *WebhooksService) ListWebhookDeliveries(ctx context.Context, boardID string, webhookID string, path string) ([]generated.WebhookDelivery, *Response, error) {
	if path == "" {
		path = fmt.Sprintf("/boards/%s/webhooks/%s/deliveries.json", boardID, webhookID)
	}
	resp, err := s.client.Get(ctx, path)
	if err != nil {
		return nil, nil, err
	}
	var result []generated.WebhookDelivery
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return result, resp, nil
}

// List returns webhooks.
func (s *WebhooksService) List(ctx context.Context, boardID string) ([]generated.Webhook, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/boards/%s/webhooks.json", boardID))
	if err != nil {
		return nil, nil, err
	}
	var result []generated.Webhook
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return result, resp, nil
}

// Update updates a webhook.
func (s *WebhooksService) Update(ctx context.Context, boardID string, webhookID string, req *generated.UpdateWebhookRequest) (*generated.Webhook, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/boards/%s/webhooks/%s", boardID, webhookID), req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.Webhook
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}
