package fizzy

import (
	"context"
	"encoding/json"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// CreateDirectUpload creates a direct upload blob for ActiveStorage.
func (s *UploadsService) CreateDirectUpload(ctx context.Context, req *generated.CreateDirectUploadRequest) (json.RawMessage, *Response, error) {
	resp, err := s.client.Post(ctx, "/rails/active_storage/direct_uploads.json", req)
	if err != nil {
		return nil, nil, err
	}
	return resp.Data, resp, nil
}
