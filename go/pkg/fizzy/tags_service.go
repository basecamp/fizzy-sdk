package fizzy

import (
	"context"
	"encoding/json"
)

// List returns all tags for the account. The path can include query params.
func (s *TagsService) List(ctx context.Context, path string) (json.RawMessage, *Response, error) {
	if path == "" {
		path = "/tags.json"
	}
	resp, err := s.client.Get(ctx, path)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// ListAll returns all tags across all pages.
func (s *TagsService) ListAll(ctx context.Context) ([]json.RawMessage, error) {
	return s.client.GetAll(ctx, "/tags.json")
}
