// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// List returns tags.
func (s *TagsService) List(ctx context.Context, path string) ([]generated.Tag, *Response, error) {
	if path == "" {
		path = "/tags.json"
	}
	resp, err := s.client.Get(ctx, path)
	if err != nil {
		return nil, nil, err
	}
	var result []generated.Tag
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return result, resp, nil
}
