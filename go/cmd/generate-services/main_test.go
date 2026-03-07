package main

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestResolveRef(t *testing.T) {
	got := resolveRef("#/components/schemas/Board")
	if got != "Board" {
		t.Errorf("resolveRef = %q, want %q", got, "Board")
	}
}

func TestResponseTypeName_Singular(t *testing.T) {
	schemas := map[string]json.RawMessage{
		"GetBoardResponseContent": json.RawMessage(`{"$ref": "#/components/schemas/Board"}`),
	}
	goType, isList := responseTypeName("GetBoardResponseContent", schemas)
	if goType != "generated.Board" || isList {
		t.Errorf("got (%q, %v), want (\"generated.Board\", false)", goType, isList)
	}
}

func TestResponseTypeName_List(t *testing.T) {
	schemas := map[string]json.RawMessage{
		"ListBoardsResponseContent": json.RawMessage(`{"type": "array", "items": {"$ref": "#/components/schemas/Board"}}`),
	}
	goType, isList := responseTypeName("ListBoardsResponseContent", schemas)
	if goType != "generated.Board" || !isList {
		t.Errorf("got (%q, %v), want (\"generated.Board\", true)", goType, isList)
	}
}

func TestResponseTypeName_Missing(t *testing.T) {
	schemas := map[string]json.RawMessage{}
	goType, isList := responseTypeName("NoSuchSchema", schemas)
	if goType != "" || isList {
		t.Errorf("got (%q, %v), want (\"\", false)", goType, isList)
	}
}

func TestGenerateMethod_TypedSingularReturn(t *testing.T) {
	op := ParsedOp{
		OperationID:     "GetBoard",
		HTTPMethod:      "GET",
		Path:            "/{accountId}/boards/{boardId}",
		PathParams:      []string{"accountId", "boardId"},
		HasResponseData: true,
		ResponseRefName: "GetBoardResponseContent",
		ResponseGoType:  "generated.Board",
		ResponseIsList:  false,
	}
	code := generateMethod("Boards", op)
	if !strings.Contains(code, "*generated.Board, *Response, error") {
		t.Errorf("expected typed return in signature, got:\n%s", code)
	}
	if !strings.Contains(code, "resp.UnmarshalData(&result)") {
		t.Errorf("expected UnmarshalData call, got:\n%s", code)
	}
	if !strings.Contains(code, "return &result, resp, nil") {
		t.Errorf("expected pointer return, got:\n%s", code)
	}
}

func TestGenerateMethod_TypedListReturn(t *testing.T) {
	op := ParsedOp{
		OperationID:     "ListBoards",
		HTTPMethod:      "GET",
		Path:            "/{accountId}/boards.json",
		PathParams:      []string{"accountId"},
		HasResponseData: true,
		HasPagination:   true,
		ResponseRefName: "ListBoardsResponseContent",
		ResponseGoType:  "generated.Board",
		ResponseIsList:  true,
	}
	code := generateMethod("Boards", op)
	if !strings.Contains(code, "[]generated.Board, *Response, error") {
		t.Errorf("expected slice return in signature, got:\n%s", code)
	}
	if !strings.Contains(code, "var result []generated.Board") {
		t.Errorf("expected slice declaration, got:\n%s", code)
	}
}

func TestGenerateMethod_QueryParams(t *testing.T) {
	op := ParsedOp{
		OperationID:     "GetNotificationTray",
		HTTPMethod:      "GET",
		Path:            "/{accountId}/notifications/tray.json",
		PathParams:      []string{"accountId"},
		HasResponseData: true,
		ResponseRefName: "GetNotificationTrayResponseContent",
		ResponseGoType:  "generated.NotificationTray",
		QueryParams: []QueryParam{
			{Name: "include_read", GoName: "includeRead", SchemaType: "boolean"},
		},
	}
	code := generateMethod("Notifications", op)
	if !strings.Contains(code, "includeRead *bool") {
		t.Errorf("expected *bool parameter, got:\n%s", code)
	}
	if !strings.Contains(code, "include_read=%t") {
		t.Errorf("expected query string formatting, got:\n%s", code)
	}
}

func TestSnakeToCamel(t *testing.T) {
	tests := []struct {
		in, want string
	}{
		{"include_read", "includeRead"},
		{"board_id", "boardId"},
		{"q", "q"},
		{"some_long_name", "someLongName"},
	}
	for _, tt := range tests {
		got := snakeToCamel(tt.in)
		if got != tt.want {
			t.Errorf("snakeToCamel(%q) = %q, want %q", tt.in, got, tt.want)
		}
	}
}
