package fizzy

import (
	_ "embed"
	"encoding/json"
	"sync"
)

//go:embed api-provenance.json
var apiProvenanceJSON []byte

// APIProvenance tracks the upstream source of the API specification.
type APIProvenance struct {
	Repo   string            `json:"repo"`
	Branch string            `json:"branch"`
	Paths  map[string]string `json:"paths,omitempty"`
}

var (
	provenance     map[string]APIProvenance
	provenanceOnce sync.Once
)

// GetAPIProvenance returns the provenance metadata for the API,
// keyed by app name (e.g., "fizzy").
func GetAPIProvenance() map[string]APIProvenance {
	provenanceOnce.Do(func() {
		if err := json.Unmarshal(apiProvenanceJSON, &provenance); err != nil {
			provenance = nil
		}
	})
	return provenance
}
