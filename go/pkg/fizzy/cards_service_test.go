package fizzy

import (
	"context"
	"net/http"
	"net/http/httptest"
	"net/url"
	"sort"
	"strings"
	"testing"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// TestListCardsRequestShape compile-references generated.ListCardsParams so
// the Go SDK is forced to rebuild whenever a filter field is added, removed,
// or renamed in the Smithy spec, and verifies CardsService.List propagates
// the constructed URL to the wire unchanged.
func TestListCardsRequestShape(t *testing.T) {
	params := &generated.ListCardsParams{
		BoardIds:  []string{"b1"},
		ColumnIds: []string{"c1", "c2"},
		IndexedBy: "maybe",
	}

	path := buildListCardsPath(params)

	var captured *http.Request
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		captured = r
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("[]"))
	}))
	defer server.Close()

	cfg := &Config{BaseURL: server.URL}
	client := NewClient(cfg, &StaticTokenProvider{Token: "test"})
	cards := client.ForAccount("999").Cards()

	if _, _, err := cards.List(context.Background(), path); err != nil {
		t.Fatalf("cards.List: %v", err)
	}
	if captured == nil {
		t.Fatal("no request captured")
	}

	q := captured.URL.Query()
	if got := q["column_ids[]"]; !equalSorted(got, []string{"c1", "c2"}) {
		t.Errorf("column_ids[] = %v, want [c1 c2]", got)
	}
	if got := q.Get("indexed_by"); got != "maybe" {
		t.Errorf("indexed_by = %q, want %q", got, "maybe")
	}
	if got := q["board_ids[]"]; !equalSorted(got, []string{"b1"}) {
		t.Errorf("board_ids[] = %v, want [b1]", got)
	}
}

func buildListCardsPath(p *generated.ListCardsParams) string {
	qv := url.Values{}
	for _, id := range p.BoardIds {
		qv.Add("board_ids[]", id)
	}
	for _, id := range p.ColumnIds {
		qv.Add("column_ids[]", id)
	}
	if p.IndexedBy != "" {
		qv.Set("indexed_by", p.IndexedBy)
	}
	if encoded := qv.Encode(); encoded != "" {
		return "/cards.json?" + encoded
	}
	return "/cards.json"
}

func equalSorted(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	ac := append([]string(nil), a...)
	bc := append([]string(nil), b...)
	sort.Strings(ac)
	sort.Strings(bc)
	return strings.Join(ac, ",") == strings.Join(bc, ",")
}
