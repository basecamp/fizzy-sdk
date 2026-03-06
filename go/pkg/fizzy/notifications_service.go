package fizzy

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// List returns notifications. The path can include query params (e.g. "?page=2").
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

// ListAll returns all notifications across all pages.
func (s *NotificationsService) ListAll(ctx context.Context) ([]json.RawMessage, error) {
	return s.client.GetAll(ctx, "/notifications.json")
}

// GetTray returns the notification tray (unread count).
func (s *NotificationsService) GetTray(ctx context.Context, includeRead bool) (json.RawMessage, *Response, error) {
	path := "/notifications/tray.json"
	if includeRead {
		path += "?include_read=true"
	}
	resp, err := s.client.Get(ctx, path)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Read marks a notification as read.
func (s *NotificationsService) Read(ctx context.Context, notificationID string) (*Response, error) {
	_, err := s.client.Post(ctx, fmt.Sprintf("/notifications/%s/reading.json", notificationID), nil)
	return nil, err
}

// Unread marks a notification as unread.
func (s *NotificationsService) Unread(ctx context.Context, notificationID string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/notifications/%s/reading.json", notificationID))
}

// BulkRead marks multiple notifications as read.
func (s *NotificationsService) BulkRead(ctx context.Context, req *generated.BulkReadNotificationsRequest) (*Response, error) {
	_, err := s.client.Post(ctx, "/notifications/bulk_reading.json", req)
	return nil, err
}
