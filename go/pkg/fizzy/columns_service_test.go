package fizzy

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// TestGetColumnDecodesColorObject pins the Column.color schema as a structured
// object (Color{name, value}) rather than a string. The live API returns
// "color": {"name": "Blue", "value": "var(--color-card-1)"}, which previously
// failed to unmarshal because the SDK typed it as a string.
func TestGetColumnDecodesColorObject(t *testing.T) {
	body := `{
		"id": "abc123",
		"name": "In Progress",
		"color": {"name": "Blue", "value": "var(--color-card-1)"},
		"created_at": "2026-04-30T00:00:00Z",
		"cards_url": "https://example.com/cards"
	}`

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(body))
	}))
	defer server.Close()

	client := NewClient(&Config{BaseURL: server.URL}, &StaticTokenProvider{Token: "test"})
	col, _, err := client.ForAccount("999").Columns().Get(context.Background(), "board1", "abc123")
	if err != nil {
		t.Fatalf("Get: %v", err)
	}
	if col.Color == nil {
		t.Fatal("Color is nil, want decoded Color object")
	}
	if col.Color.Name != "Blue" {
		t.Errorf("Color.Name = %q, want Blue", col.Color.Name)
	}
	if col.Color.Value != "var(--color-card-1)" {
		t.Errorf("Color.Value = %q, want var(--color-card-1)", col.Color.Value)
	}
}

func TestColumnColorOptionalPointerOmitsAbsentColor(t *testing.T) {
	var col generated.Column
	if err := json.Unmarshal([]byte(`{"id":"abc123","name":"No Color","created_at":"2026-04-30T00:00:00Z"}`), &col); err != nil {
		t.Fatalf("Unmarshal: %v", err)
	}
	if col.Color != nil {
		t.Fatalf("Color = %+v, want nil for absent optional field", col.Color)
	}
	encoded, err := json.Marshal(col)
	if err != nil {
		t.Fatalf("Marshal: %v", err)
	}
	if strings.Contains(string(encoded), `"color"`) {
		t.Fatalf("encoded Column contains absent color: %s", encoded)
	}
}

// TestListColumnsDecodesColorObject mirrors the Get test for the list endpoint.
func TestListColumnsDecodesColorObject(t *testing.T) {
	body := `[
		{"id": "c1", "name": "Triage", "color": {"name": "Gray", "value": "var(--color-card-1)"}, "created_at": "2026-04-30T00:00:00Z"},
		{"id": "c2", "name": "Done",   "color": {"name": "Lime", "value": "var(--color-card-4)"}, "created_at": "2026-04-30T00:00:00Z"}
	]`

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(body))
	}))
	defer server.Close()

	client := NewClient(&Config{BaseURL: server.URL}, &StaticTokenProvider{Token: "test"})
	cols, _, err := client.ForAccount("999").Columns().List(context.Background(), "board1")
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if len(cols) != 2 {
		t.Fatalf("len(cols) = %d, want 2", len(cols))
	}
	if cols[0].Color == nil || cols[1].Color == nil {
		t.Fatalf("colors = %+v / %+v, want decoded Color objects", cols[0].Color, cols[1].Color)
	}
	if cols[0].Color.Name != "Gray" || cols[1].Color.Value != "var(--color-card-4)" {
		t.Errorf("unexpected colors: %+v / %+v", cols[0].Color, cols[1].Color)
	}
}
