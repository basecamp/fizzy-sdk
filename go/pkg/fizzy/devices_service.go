// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"fmt"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Register performs the Register operation on a device.
func (s *DevicesService) Register(ctx context.Context, accountID string, req *generated.RegisterDeviceRequest) (*Response, error) {
	resp, err := s.client.Post(ctx, fmt.Sprintf("/%s/devices", accountID), req)
	return resp, err
}

// Unregister performs the Unregister operation on a device.
func (s *DevicesService) Unregister(ctx context.Context, accountID string, deviceToken string) (*Response, error) {
	return s.client.Delete(ctx, fmt.Sprintf("/%s/devices/%s", accountID, deviceToken))
}
