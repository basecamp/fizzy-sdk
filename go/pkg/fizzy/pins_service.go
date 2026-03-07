// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// List returns pins.
func (s *PinsService) List(ctx context.Context) ([]generated.Pin, *Response, error) {
	resp, err := s.client.Get(ctx, "/my/pins.json")
	if err != nil {
		return nil, nil, err
	}
	var result []generated.Pin
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return result, resp, nil
}
