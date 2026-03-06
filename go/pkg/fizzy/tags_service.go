// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"encoding/json"
)

// List returns tags.
func (s *TagsService) List(ctx context.Context) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, "/tags.json")
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}
