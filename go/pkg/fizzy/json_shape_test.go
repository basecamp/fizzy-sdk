package fizzy

import (
	"context"
	"encoding/json"
	"go/ast"
	"go/parser"
	"go/token"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"reflect"
	"regexp"
	"sort"
	"strings"
	"testing"

	"github.com/basecamp/fizzy-sdk/go/pkg/generated"
)

// structField is one exported field of a struct declared in a package's source.
type structField struct {
	Name  string
	Slice bool
	Tag   reflect.StructTag
}

// parseStructs reads every non-test .go file in dir and returns the exported
// fields of each exported struct type, keyed by type name.
func parseStructs(t *testing.T, dir string) map[string][]structField {
	t.Helper()
	files, err := filepath.Glob(filepath.Join(dir, "*.go"))
	if err != nil {
		t.Fatal(err)
	}
	structs := map[string][]structField{}
	fset := token.NewFileSet()
	for _, path := range files {
		if strings.HasSuffix(path, "_test.go") {
			continue
		}
		file, err := parser.ParseFile(fset, path, nil, parser.SkipObjectResolution)
		if err != nil {
			t.Fatal(err)
		}
		ast.Inspect(file, func(n ast.Node) bool {
			spec, ok := n.(*ast.TypeSpec)
			if !ok || !spec.Name.IsExported() || spec.Assign.IsValid() {
				return true
			}
			st, ok := spec.Type.(*ast.StructType)
			if !ok {
				return true
			}
			fields := []structField{}
			for _, f := range st.Fields.List {
				var tag reflect.StructTag
				if f.Tag != nil {
					tag = reflect.StructTag(strings.Trim(f.Tag.Value, "`"))
				}
				_, slice := f.Type.(*ast.ArrayType)
				for _, name := range f.Names {
					if name.IsExported() {
						fields = append(fields, structField{Name: name.Name, Slice: slice, Tag: tag})
					}
				}
			}
			structs[spec.Name.Name] = fields
			return true
		})
	}
	return structs
}

// jsonName is the key a json tag gives a field.
func jsonName(tag reflect.StructTag) (name string, ok bool) {
	raw, ok := tag.Lookup("json")
	name, _, _ = strings.Cut(raw, ",")
	return name, ok
}

// isQueryParams reports whether a generated type carries query parameters
// (form-tagged fields), which are encoded into the URL, never as a JSON body.
func isQueryParams(fields []structField) bool {
	for _, f := range fields {
		if _, ok := f.Tag.Lookup("form"); ok {
			return true
		}
	}
	return false
}

// emptyListTypes is every generated JSON type with a list field. The
// coverage check below fails when the spec adds one that isn't listed here,
// so a new list field can't skip the round-trip sweep.
var emptyListTypes = map[string]func() any{
	"ActivityEventable":                   func() any { return new(generated.ActivityEventable) },
	"ActivityParticulars":                 func() any { return new(generated.ActivityParticulars) },
	"Board":                               func() any { return new(generated.Board) },
	"BoardAccesses":                       func() any { return new(generated.BoardAccesses) },
	"BulkReadNotificationsRequestContent": func() any { return new(generated.BulkReadNotificationsRequestContent) },
	"Card":                                func() any { return new(generated.Card) },
	"CreateWebhookRequestContent":         func() any { return new(generated.CreateWebhookRequestContent) },
	"Identity":                            func() any { return new(generated.Identity) },
	"UpdateBoardRequestContent":           func() any { return new(generated.UpdateBoardRequestContent) },
	"UpdateWebhookRequestContent":         func() any { return new(generated.UpdateWebhookRequestContent) },
	"ValidationErrorResponseContent":      func() any { return new(generated.ValidationErrorResponseContent) },
	"Webhook":                             func() any { return new(generated.Webhook) },
}

// TestGeneratedEmptyListsSurviveRoundTrip feeds every generated type with a
// list field a fixture where each list is [], and checks the lists decode to
// non-nil empty slices and marshal back as []. It also checks the other half:
// a list the server left out stays out, rather than turning into [] or null.
func TestGeneratedEmptyListsSurviveRoundTrip(t *testing.T) {
	structs := parseStructs(t, filepath.Join("..", "generated"))

	want := []string{}
	for name, fields := range structs {
		if isQueryParams(fields) {
			continue
		}
		for _, f := range fields {
			if f.Slice {
				want = append(want, name)
				break
			}
		}
	}
	sort.Strings(want)
	have := make([]string, 0, len(emptyListTypes))
	for name := range emptyListTypes {
		have = append(have, name)
	}
	sort.Strings(have)
	if !reflect.DeepEqual(want, have) {
		t.Fatalf("emptyListTypes is out of step with the generated types with list fields:\n got %v\nwant %v", have, want)
	}

	for _, name := range want {
		t.Run(name, func(t *testing.T) {
			keys := []string{}
			fixture := map[string]any{}
			for _, f := range structs[name] {
				if !f.Slice {
					continue
				}
				key, ok := jsonName(f.Tag)
				if !ok {
					t.Fatalf("%s.%s has no json tag", name, f.Name)
				}
				keys = append(keys, key)
				fixture[key] = []any{}
			}
			body, _ := json.Marshal(fixture)

			v := emptyListTypes[name]()
			if err := json.Unmarshal(body, v); err != nil {
				t.Fatalf("Unmarshal %s: %v", body, err)
			}
			rv := reflect.ValueOf(v).Elem()
			for _, f := range structs[name] {
				if f.Slice && rv.FieldByName(f.Name).IsNil() {
					t.Errorf("%s.%s decoded [] as nil", name, f.Name)
				}
			}
			out := marshalToMap(t, v)
			for _, key := range keys {
				if got := string(out[key]); got != "[]" {
					t.Errorf("%s re-marshaled %q as %q, want []", name, key, got)
				}
			}

			absent := emptyListTypes[name]()
			if err := json.Unmarshal([]byte(`{}`), absent); err != nil {
				t.Fatalf("Unmarshal {}: %v", err)
			}
			out = marshalToMap(t, absent)
			for _, key := range keys {
				if got, ok := out[key]; ok {
					t.Errorf("%s marshaled absent %q as %s, want it left out", name, key, got)
				}
			}
		})
	}
}

func marshalToMap(t *testing.T, v any) map[string]json.RawMessage {
	t.Helper()
	encoded, err := json.Marshal(v)
	if err != nil {
		t.Fatalf("Marshal: %v", err)
	}
	out := map[string]json.RawMessage{}
	if err := json.Unmarshal(encoded, &out); err != nil {
		t.Fatalf("Unmarshal %s: %v", encoded, err)
	}
	return out
}

// TestRequestBodySendsEmptyList checks a caller can clear a list: an
// UpdateBoard with UserIds set to an empty slice reaches the server as
// "user_ids": [], where omitempty used to drop the key.
func TestRequestBodySendsEmptyList(t *testing.T) {
	var got map[string]json.RawMessage
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if err := json.NewDecoder(r.Body).Decode(&got); err != nil {
			t.Errorf("decode body: %v", err)
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"id":"b1"}`))
	}))
	defer server.Close()

	client := NewClient(&Config{BaseURL: server.URL}, &StaticTokenProvider{Token: "test"})
	req := &generated.UpdateBoardRequest{UserIds: []string{}}
	if _, _, err := client.ForAccount("999").Boards().Update(context.Background(), "b1", req); err != nil {
		t.Fatalf("Update: %v", err)
	}
	if string(got["user_ids"]) != "[]" {
		t.Fatalf(`body user_ids = %q, want [] (body %v)`, got["user_ids"], got)
	}
}

// TestGetAllKeepsEmptyList checks GetAll hands back an empty, non-nil slice
// when the server sends [], so it re-marshals as [] rather than null.
func TestGetAllKeepsEmptyList(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`[]`))
	}))
	defer server.Close()

	client := NewClient(&Config{BaseURL: server.URL}, &StaticTokenProvider{Token: "test"})
	items, err := client.GetAll(context.Background(), "/999/cards.json")
	if err != nil {
		t.Fatalf("GetAll: %v", err)
	}
	if items == nil {
		t.Fatal("GetAll returned nil for a server-sent []")
	}
	if encoded, _ := json.Marshal(items); string(encoded) != "[]" {
		t.Fatalf("GetAll result marshals as %s, want []", encoded)
	}
}

// wireKey is the shape of a JSON key the SDK writes: snake_case, with a
// trailing [] on array query parameters.
var wireKey = regexp.MustCompile(`^[a-z][a-z0-9_]*(\[\])?$`)

// wireKeyExceptions are keys Fizzy itself sends in another case; the SDK must
// keep them as sent.
var wireKeyExceptions = map[string]string{
	"Content_Type": "direct-upload header name, sent by Fizzy as-is",
	"Content_MD5":  "direct-upload header name, sent by Fizzy as-is",
}

// untaggedTypes are exported structs in package fizzy that carry no API data,
// so their Go field names never reach JSON the SDK writes. Each needs a reason.
var untaggedTypes = map[string]string{
	"AccountClient":        "client handle",
	"AuthManager":          "client handle",
	"BearerAuth":           "auth strategy",
	"BulkheadConfig":       "Go-side resilience settings",
	"Cache":                "client handle",
	"ChainHooks":           "hook plumbing",
	"CircuitBreakerConfig": "Go-side resilience settings",
	"Client":               "client handle",
	"CookieAuth":           "auth strategy",
	"CredentialStore":      "client handle",
	"Error":                "Go error value; callers render it, the SDK never marshals it",
	"HTTPOptions":          "Go-side transport settings",
	"MagicLinkFlow":        "flow handle",
	"NoopHooks":            "hook plumbing",
	"OperationInfo":        "hook callback argument",
	"RateLimitConfig":      "Go-side resilience settings",
	"RequestInfo":          "hook callback argument",
	"RequestResult":        "hook callback argument",
	"ResilienceConfig":     "Go-side resilience settings",
	"Response":             "transport envelope; Data holds the API JSON verbatim",
	"SlogHooks":            "hook plumbing",
	"StaticTokenProvider":  "auth token holder",
}

// TestExportedTypesUseSnakeCaseJSONKeys checks every exported field of every
// exported struct the SDK may serialize, generated or hand-written, has a json
// tag with a snake_case key, so a caller marshaling one gets the API's keys
// (created_at), not Go's (CreatedAt). Structs with no data are listed in
// untaggedTypes with the reason they're exempt.
func TestExportedTypesUseSnakeCaseJSONKeys(t *testing.T) {
	for _, dir := range []string{filepath.Join("..", "generated"), "."} {
		for name, fields := range parseStructs(t, dir) {
			if dir == "." {
				if _, exempt := untaggedTypes[name]; exempt {
					continue
				}
			}
			for _, f := range fields {
				key, ok := jsonName(f.Tag)
				switch {
				case !ok:
					t.Errorf("%s: %s.%s has no json tag (tag it, or list %s in untaggedTypes with a reason)", dir, name, f.Name, name)
				case key == "-":
				case wireKeyExceptions[key] != "":
				case !wireKey.MatchString(key):
					t.Errorf("%s: %s.%s marshals as %q, want a snake_case key", dir, name, f.Name, key)
				}
			}
		}
	}

	hand := parseStructs(t, ".")
	for name := range untaggedTypes {
		if _, ok := hand[name]; !ok {
			t.Errorf("untaggedTypes lists %s, which package fizzy no longer declares", name)
		}
	}
}
