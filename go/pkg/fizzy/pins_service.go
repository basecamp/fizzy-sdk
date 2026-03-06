// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"encoding/json"
)

// List returns pins.
func (s *PinsService) List(ctx context.Context) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, "/my/pins.json")
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}
