package fizzy

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
)

// parseNextLink extracts the next URL from a Link header.
func parseNextLink(linkHeader string) string {
	if linkHeader == "" {
		return ""
	}

	for _, part := range strings.Split(linkHeader, ",") {
		part = strings.TrimSpace(part)
		if strings.Contains(part, `rel="next"`) {
			start := strings.Index(part, "<")
			end := strings.Index(part, ">")
			if start >= 0 && end > start {
				return part[start+1 : end]
			}
		}
	}

	return ""
}

// FollowPagination fetches additional pages following Link headers from an HTTP response.
// This is used after calling the generated client for the first page.
// The httpResp should be from the generated client's *WithResponse method.
// firstPageCount is the number of items already collected from the first page.
// limit is the maximum total items to return (0 = unlimited).
// Returns raw JSON items from subsequent pages only (first page items are handled by caller).
//
// Fizzy does not emit X-Total-Count headers. Pagination relies solely on Link headers.
//
// Security: Link headers are resolved against the current page URL and validated
// for same-origin against the original request to prevent SSRF and token leakage.
func (c *Client) FollowPagination(ctx context.Context, httpResp *http.Response, firstPageCount, limit int) ([]json.RawMessage, error) {
	if httpResp == nil {
		return nil, nil
	}

	if limit > 0 && firstPageCount >= limit {
		return nil, nil
	}

	nextLink := parseNextLink(httpResp.Header.Get("Link"))
	if nextLink == "" {
		return nil, nil
	}

	// Require httpResp.Request.URL for same-origin validation.
	if httpResp.Request == nil || httpResp.Request.URL == nil {
		return nil, fmt.Errorf("cannot follow pagination: response has no request URL (required for same-origin validation)")
	}
	baseURL := httpResp.Request.URL.String()

	nextURL := resolveURL(baseURL, nextLink)

	parsedURL, err := url.Parse(nextURL)
	if err != nil || !parsedURL.IsAbs() {
		return nil, fmt.Errorf("failed to resolve Link header URL %q against %q", nextLink, baseURL)
	}

	if !isSameOrigin(baseURL, nextURL) {
		return nil, fmt.Errorf("pagination Link header points to different origin: %s", nextURL)
	}

	var allResults []json.RawMessage
	currentCount := firstPageCount
	var page int

	for page = 2; page <= c.httpOpts.MaxPages && nextURL != ""; page++ {
		currentPageURL := nextURL

		resp, err := c.doRequestURL(ctx, "GET", nextURL, nil)
		if err != nil {
			return nil, err
		}

		var items []json.RawMessage
		if err := json.Unmarshal(resp.Data, &items); err != nil {
			return nil, fmt.Errorf("failed to parse response: %w", err)
		}
		allResults = append(allResults, items...)
		currentCount += len(items)

		if limit > 0 && currentCount >= limit {
			excess := currentCount - limit
			if excess > 0 && len(allResults) > excess {
				allResults = allResults[:len(allResults)-excess]
			}
			break
		}

		nextLink = parseNextLink(resp.Headers.Get("Link"))
		if nextLink == "" {
			break
		}
		nextURL = resolveURL(currentPageURL, nextLink)

		if !isSameOrigin(baseURL, nextURL) {
			return nil, fmt.Errorf("pagination Link header points to different origin: %s", nextURL)
		}
	}

	if page > c.httpOpts.MaxPages {
		c.logger.Warn("pagination capped", "maxPages", c.httpOpts.MaxPages)
	}

	return allResults, nil
}
