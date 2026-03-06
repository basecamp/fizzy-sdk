package fizzy

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Register registers a device for push notifications.
// Note: Devices are account-scoped in the API but the service is on Client
// for convenience. The accountID must be provided.
func (s *DevicesService) Register(ctx context.Context, accountID string, req *generated.RegisterDeviceRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/%s/devices.json", accountID), req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}

// Unregister unregisters a device.
func (s *DevicesService) Unregister(ctx context.Context, accountID, deviceToken string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/%s/devices/%s.json", accountID, deviceToken))
}
