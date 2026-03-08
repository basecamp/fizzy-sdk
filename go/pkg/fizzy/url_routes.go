package fizzy

import (
	_ "embed"
	"encoding/json"
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
