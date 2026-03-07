// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// CreateDirectUpload creates an upload.
func (s *UploadsService) CreateDirectUpload(ctx context.Context, req *generated.CreateDirectUploadRequest) (*generated.DirectUpload, *Response, error) {
	resp, err := s.client.Post(ctx, "/rails/active_storage/direct_uploads", req)
	if err != nil {
		return nil, nil, err
	}
	var result generated.DirectUpload
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return &result, resp, nil
}
