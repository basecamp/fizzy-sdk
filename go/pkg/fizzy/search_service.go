// Code generated from openapi.json — DO NOT EDIT.
package fizzy

import (
	"context"
	"fmt"
	"net/url"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// Search performs the Search operation on a search.
func (s *SearchService) Search(ctx context.Context, q *string) ([]generated.Card, *Response, error) {
	path := "/search.json"
	sep := "?"
	if q != nil {
		path += fmt.Sprintf("%sq=%s", sep, url.QueryEscape(*q))
		sep = "&"
	}
	resp, err := s.client.Get(ctx, path)
	if err != nil {
		return nil, nil, err
	}
	var result []generated.Card
	if err := resp.UnmarshalData(&result); err != nil {
		return nil, resp, err
	}
	return result, resp, nil
}
