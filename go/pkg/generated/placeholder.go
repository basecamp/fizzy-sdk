// Package generated contains generated API client code from the OpenAPI spec.
//
// Do not edit files in this package directly. They are regenerated
// by running `go generate ./...` from the go directory.
//
// This placeholder file exists so the package is importable before
// code generation runs. After generation, the actual client code will
// be in client.gen.go alongside this file.
package generated

import (
	"context"
	"net/http"
)

// RequestEditorFn is the function signature for the RequestEditor callback function.
type RequestEditorFn func(ctx context.Context, req *http.Request) error

// HTTPRequestDoer performs HTTP requests.
type HTTPRequestDoer interface {
	Do(req *http.Request) (*http.Response, error)
}

// ClientWithResponses is the generated client with parsed responses.
// This placeholder will be replaced by the generated version.
type ClientWithResponses struct {
	ClientInterface
}

// ClientInterface is the interface for the generated client.
type ClientInterface interface{}

// ClientOption allows setting custom parameters during construction.
type ClientOption func(*Client) error

// Client is the generated low-level client.
type Client struct {
	Server         string
	Client         HTTPRequestDoer
	RequestEditors []RequestEditorFn
}

// WithHTTPClient allows overriding the default Doer.
func WithHTTPClient(doer HTTPRequestDoer) ClientOption {
	return func(c *Client) error {
		c.Client = doer
		return nil
	}
}

// WithRequestEditorFn allows setting up a callback function.
func WithRequestEditorFn(fn RequestEditorFn) ClientOption {
	return func(c *Client) error {
		c.RequestEditors = append(c.RequestEditors, fn)
		return nil
	}
}

// NewClientWithResponses creates a new ClientWithResponses.
func NewClientWithResponses(server string, opts ...ClientOption) (*ClientWithResponses, error) {
	return &ClientWithResponses{}, nil
}
