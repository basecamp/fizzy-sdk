package fizzy

import (
	"context"
	"encoding/json"
)

// List returns all pinned cards for the authenticated user.
func (s *PinsService) List(ctx context.Context) (json.RawMessage, *Response, error) {
	resp, err := s.client.Get(ctx, "/my/pins.json")
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}
