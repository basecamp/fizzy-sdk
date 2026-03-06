// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// BulkRead performs the BulkRead operation on a notification.
func (s *NotificationsService) BulkRead(ctx context.Context, req *generated.BulkReadNotificationsRequest) (*Response, error) {
	resp, err := s.client.Post(ctx, "/notifications/bulk_reading.json", req)
	return resp, err
}

// GetTray returns a tray.
func (s *NotificationsService) GetTray(ctx context.Context) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, "/notifications/tray.json")
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// List returns notifications.
func (s *NotificationsService) List(ctx context.Context, path string) (json.RawMessage, *Response, error) {
	if path == "" {
		path = "/notifications.json"
	}
	resp, err := s.client.Get(ctx, path)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Read performs the Read operation on a notification.
func (s *NotificationsService) Read(ctx context.Context, notificationID string) (*Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/notifications/%s/reading.json", notificationID), nil)
	return resp, err
}

// Unread performs the Unread operation on a notification.
func (s *NotificationsService) Unread(ctx context.Context, notificationID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/notifications/%s/reading.json", notificationID))
}
