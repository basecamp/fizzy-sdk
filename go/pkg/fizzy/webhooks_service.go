package fizzy

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// List returns webhooks for a board.
func (s *WebhooksService) List(ctx context.Context, boardID string) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/boards/%s/webhooks.json", boardID))
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Get returns a single webhook.
func (s *WebhooksService) Get(ctx context.Context, boardID, webhookID string) (*generated.Webhook, *Response, error) {
	resp, err := s.client.Get(ctx, fmt.Sprintf("/boards/%s/webhooks/%s.json", boardID, webhookID))
	if err != nil {
		return nil, nil, err
	}
	var wh generated.Webhook
	if err := resp.UnmarshalData(&wh); err != nil {
		return nil, resp, err
	}
	return &wh, resp, nil
}

// Create creates a new webhook on a board.
func (s *WebhooksService) Create(ctx context.Context, boardID string, req *generated.CreateWebhookRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/boards/%s/webhooks.json", boardID), req)
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

// Update updates a webhook.
func (s *WebhooksService) Update(ctx context.Context, boardID, webhookID string, req *generated.UpdateWebhookRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Patch(ctx, fmt.Sprintf("/boards/%s/webhooks/%s.json", boardID, webhookID), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Delete deletes a webhook.
func (s *WebhooksService) Delete(ctx context.Context, boardID, webhookID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/boards/%s/webhooks/%s.json", boardID, webhookID))
}

// Activate activates a webhook.
func (s *WebhooksService) Activate(ctx context.Context, boardID, webhookID string) (*Response, error) {
	_, err := s.client.Post(ctx, fmt.Sprintf("/boards/%s/webhooks/%s/activation.json", boardID, webhookID), nil)
	return nil, err
}
