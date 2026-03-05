package fizzy

import (
	_ "embed"
	"encoding/json"
	"sync"
)

//go:embed url-routes.json
var urlRoutesJSON []byte

// URLRoute describes a single API route pattern.
type URLRoute struct {
	OperationID string            `json:"operationId"`
	Method      string            `json:"method"`
	Path        string            `json:"path"`
	Params      map[string]string `json:"params,omitempty"`
}

var (
	urlRoutes     []URLRoute
	urlRoutesOnce sync.Once
)

// URLRoutes returns the list of all API route patterns.
// The data is parsed once from the embedded url-routes.json.
func URLRoutes() []URLRoute {
	urlRoutesOnce.Do(func() {
		if err := json.Unmarshal(urlRoutesJSON, &urlRoutes); err != nil {
			urlRoutes = nil
		}
	})
	return urlRoutes
}

// URLRouteByOperation returns the route pattern for the given operation ID.
func URLRouteByOperation(operationID string) (URLRoute, bool) {
	for _, r := range URLRoutes() {
		if r.OperationID == operationID {
			return r, true
		}
	}
	return URLRoute{}, false
}
