package fizzy

import (
	_ "embed"
	"encoding/json"
	"net/url"
	"strings"
	"sync"
)

//go:embed url-routes.json
var urlRoutesJSON []byte

// URLRouteParam describes a path parameter in a route pattern.
type URLRouteParam struct {
	Role string `json:"role"`
	Type string `json:"type"`
}

// URLRoute describes a single API route pattern.
type URLRoute struct {
	Pattern    string                   `json:"pattern"`
	APIPath    string                   `json:"api_path"`
	Resource   string                   `json:"resource"`
	Operations map[string]string        `json:"operations"`
	Params     map[string]URLRouteParam `json:"params"`
}

type urlRoutesFile struct {
	Routes []URLRoute `json:"routes"`
}

var (
	urlRoutes     []URLRoute
	urlRoutesOnce sync.Once
)

// URLRoutes returns the list of all API route patterns.
// The data is parsed once from the embedded url-routes.json.
func URLRoutes() []URLRoute {
	urlRoutesOnce.Do(func() {
		var f urlRoutesFile
		if err := json.Unmarshal(urlRoutesJSON, &f); err != nil {
			urlRoutes = nil
		} else {
			urlRoutes = f.Routes
		}
	})
	return urlRoutes
}

// URLRouteByOperation returns the route pattern for the given operation ID.
func URLRouteByOperation(operationID string) (URLRoute, bool) {
	for _, r := range URLRoutes() {
		for _, opID := range r.Operations {
			if opID == operationID {
				return r, true
			}
		}
	}
	return URLRoute{}, false
}

// URLPathByOperation returns the API path for an operation with path parameters applied.
// The path comes from the generated route table and uses URL-escaped parameter values.
func URLPathByOperation(operationID string, params map[string]string) (string, bool) {
	route, ok := URLRouteByOperation(operationID)
	if !ok {
		return "", false
	}

	path := route.APIPath
	if path == "" {
		path = route.Pattern
	}
	for name := range route.Params {
		value, ok := params[name]
		if !ok {
			return "", false
		}
		path = strings.ReplaceAll(path, "{"+name+"}", url.PathEscape(value))
	}
	if strings.Contains(path, "{") {
		return "", false
	}
	return path, true
}
