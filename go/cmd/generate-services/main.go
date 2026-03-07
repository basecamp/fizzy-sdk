// generate-services reads openapi.json and generates Go service method files
// in go/pkg/fizzy/. It produces one file per service containing the method
// implementations derived from the OpenAPI operationIds.
//
// Usage: go run ./cmd/generate-services/
package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

// ---------------------------------------------------------------------------
// OpenAPI types (minimal, only what we need)
// ---------------------------------------------------------------------------

type OpenAPISpec struct {
	Paths      map[string]PathItem `json:"paths"`
	Components struct {
		Schemas map[string]json.RawMessage `json:"schemas"`
	} `json:"components"`
}

type PathItem map[string]json.RawMessage // method -> Operation (or other fields)

type Operation struct {
	OperationID string      `json:"operationId"`
	Parameters  []Parameter `json:"parameters"`
	RequestBody *struct {
		Content map[string]struct {
			Schema SchemaRef `json:"schema"`
		} `json:"content"`
	} `json:"requestBody"`
	Responses  map[string]ResponseDef `json:"responses"`
	Pagination *json.RawMessage       `json:"x-fizzy-pagination"`
}

type Parameter struct {
	Name   string `json:"name"`
	In     string `json:"in"`
	Schema struct {
		Type string `json:"type"`
	} `json:"schema"`
}

// QueryParam represents a parsed query parameter for code generation.
type QueryParam struct {
	Name       string // original name from spec, e.g. "include_read"
	GoName     string // Go parameter name, e.g. "includeRead"
	SchemaType string // JSON schema type, e.g. "boolean", "string", "integer"
}

type ResponseDef struct {
	Content map[string]struct {
		Schema SchemaRef `json:"schema"`
	} `json:"content"`
}

type SchemaRef struct {
	Ref string `json:"$ref"`
}

// ---------------------------------------------------------------------------
// Behavior model types
// ---------------------------------------------------------------------------

type BehaviorModel struct {
	Operations map[string]BehaviorEntry `json:"operations"`
}

type BehaviorEntry struct {
	Retry struct {
		RetryOn json.RawMessage `json:"retry_on"`
	} `json:"retry"`
}

// ---------------------------------------------------------------------------
// Parsed operation
// ---------------------------------------------------------------------------

type ParsedOp struct {
	OperationID     string
	HTTPMethod      string // GET, POST, PATCH, DELETE
	Path            string // raw path from spec
	PathParams      []string
	QueryParams     []QueryParam
	HasRequestBody  bool
	BodyRefName     string // e.g. "CreateBoardRequestContent"
	HasResponseData bool
	ResponseRefName string // e.g. "GetBoardResponseContent"
	ResponseGoType  string // e.g. "generated.Board" (resolved at parse time)
	ResponseIsList  bool   // true for []generated.Board
	HasPagination   bool
	NoRetry         bool // true for non-POST operations with retry_on: null
}

// SchemaDef is a minimal representation of a JSON Schema definition used
// to resolve response content schemas to Go type names.
type SchemaDef struct {
	Ref   string     `json:"$ref"`
	Type  string     `json:"type"`
	Items *SchemaDef `json:"items"`
}

// resolveRef extracts the last path component from a $ref string.
// e.g. "#/components/schemas/Board" -> "Board"
func resolveRef(ref string) string {
	parts := strings.Split(ref, "/")
	return parts[len(parts)-1]
}

// responseTypeName resolves a ResponseContent schema name to a Go type.
// Returns the Go type string (e.g. "generated.Board") and whether it's a list.
func responseTypeName(refName string, schemas map[string]json.RawMessage) (goType string, isList bool) {
	raw, ok := schemas[refName]
	if !ok {
		return "", false
	}
	var def SchemaDef
	if err := json.Unmarshal(raw, &def); err != nil {
		return "", false
	}
	if def.Type == "array" && def.Items != nil && def.Items.Ref != "" {
		return "generated." + resolveRef(def.Items.Ref), true
	}
	if def.Ref != "" {
		return "generated." + resolveRef(def.Ref), false
	}
	return "", false
}

// ---------------------------------------------------------------------------
// Service grouping
// ---------------------------------------------------------------------------

// operationServiceOverrides maps operationId to service name for operations
// whose service cannot be derived from suffix matching.
var operationServiceOverrides = map[string]string{
	"GetMyIdentity":         "Identity",
	"CreateDirectUpload":    "Uploads",
	"RedeemMagicLink":       "Sessions",
	"CompleteSignup":        "Sessions",
	"GetNotificationTray":   "Notifications",
	"BulkReadNotifications": "Notifications",
	"DeleteCardImage":       "Cards",
}

// serviceSuffixes is checked longest-first to map operationId to a service.
var serviceSuffixes = []struct {
	suffix  string
	service string
}{
	{"CommentReactions", "Reactions"},
	{"CommentReaction", "Reactions"},
	{"CardReactions", "Reactions"},
	{"CardReaction", "Reactions"},
	{"Notifications", "Notifications"},
	{"Notification", "Notifications"},
	{"Comments", "Comments"},
	{"Comment", "Comments"},
	{"Webhooks", "Webhooks"},
	{"Webhook", "Webhooks"},
	{"Columns", "Columns"},
	{"Column", "Columns"},
	{"Boards", "Boards"},
	{"Board", "Boards"},
	{"Cards", "Cards"},
	{"Card", "Cards"},
	{"Steps", "Steps"},
	{"Step", "Steps"},
	{"Users", "Users"},
	{"User", "Users"},
	{"Tags", "Tags"},
	{"Pins", "Pins"},
	{"Session", "Sessions"},
	{"Device", "Devices"},
}

func deriveServiceName(opID string) string {
	if svc, ok := operationServiceOverrides[opID]; ok {
		return svc
	}
	for _, entry := range serviceSuffixes {
		if strings.HasSuffix(opID, entry.suffix) {
			return entry.service
		}
	}
	log.Fatalf("cannot derive service for operationId %q", opID)
	return ""
}

// ---------------------------------------------------------------------------
// Method naming
// ---------------------------------------------------------------------------

// methodNameOverrides maps operationId -> Go method name for cases that don't
// follow simple prefix-stripping.
var methodNameOverrides = map[string]string{
	"GetMyIdentity":         "GetMyIdentity",
	"RedeemMagicLink":       "RedeemMagicLink",
	"CompleteSignup":        "CompleteSignup",
	"DestroySession":        "Destroy",
	"DeleteCardImage":       "DeleteImage",
	"GetNotificationTray":   "GetTray",
	"BulkReadNotifications": "BulkRead",
	"ReadNotification":      "Read",
	"UnreadNotification":    "Unread",
	"CreateDirectUpload":    "CreateDirectUpload",
	"RegisterDevice":        "Register",
	"UnregisterDevice":      "Unregister",
	"DeactivateUser":        "Deactivate",
	"ActivateWebhook":       "Activate",
	"ListCardReactions":     "ListCard",
	"CreateCardReaction":    "CreateCard",
	"DeleteCardReaction":    "DeleteCard",
	"ListCommentReactions":  "ListComment",
	"CreateCommentReaction": "CreateComment",
	"DeleteCommentReaction": "DeleteComment",
}

// serviceResourceSuffixes maps service name to the suffix that should be
// stripped from the operationId to derive the method name. Plural form used
// for List operations is handled separately.
var serviceResourceSuffixes = map[string][]string{
	"Boards":        {"Boards", "Board"},
	"Cards":         {"Cards", "Card"},
	"Columns":       {"Columns", "Column"},
	"Comments":      {"Comments", "Comment"},
	"Steps":         {"Steps", "Step"},
	"Notifications": {"Notifications", "Notification"},
	"Tags":          {"Tags", "Tag"},
	"Users":         {"Users", "User"},
	"Pins":          {"Pins", "Pin"},
	"Webhooks":      {"Webhooks", "Webhook"},
	"Reactions":     {"Reactions", "Reaction"},
	"Sessions":      {"Sessions", "Session"},
	"Devices":       {"Devices", "Device"},
	"Uploads":       {"Uploads", "Upload"},
	"Identity":      {"Identity"},
}

func deriveMethodName(opID, serviceName string) string {
	if name, ok := methodNameOverrides[opID]; ok {
		return name
	}
	suffixes, ok := serviceResourceSuffixes[serviceName]
	if ok {
		for _, suffix := range suffixes {
			if strings.HasSuffix(opID, suffix) {
				name := strings.TrimSuffix(opID, suffix)
				if name != "" {
					return name
				}
			}
		}
	}
	return opID
}

// ---------------------------------------------------------------------------
// Client type determination
// ---------------------------------------------------------------------------

// accountIndependentServices are services that use *Client (not *AccountClient).
// Determined by: if ANY operation has {accountId} in path, it's account-scoped.
// Only services where NO operation has {accountId} use *Client.
//
// Exception: Devices has {accountId} in its paths but is declared on *Client
// in client.go. It takes accountID as an explicit method parameter instead.
var accountIndependentServices = map[string]bool{
	"Identity": true,
	"Sessions": true,
	"Devices":  true,
}

// isAccountScoped returns true if the service uses *AccountClient.
func isAccountScoped(serviceName string) bool {
	return !accountIndependentServices[serviceName]
}

// ---------------------------------------------------------------------------
// Path handling
// ---------------------------------------------------------------------------

// stripAccountPrefix removes /{accountId} from the beginning of a path
// since AccountClient prepends it automatically.
func stripAccountPrefix(path string) string {
	if strings.HasPrefix(path, "/{accountId}/") {
		return "/" + path[len("/{accountId}/"):]
	}
	if path == "/{accountId}" {
		return "/"
	}
	return path
}

var pathParamRe = regexp.MustCompile(`\{(\w+)\}`)

// goFormatPath converts an OpenAPI path like "/boards/{boardId}/columns/{columnId}"
// to a Go fmt.Sprintf template and returns the param names in order.
func goFormatPath(path string, skipParams map[string]bool) (fmtStr string, params []string) {
	fmtStr = pathParamRe.ReplaceAllStringFunc(path, func(match string) string {
		name := match[1 : len(match)-1]
		if skipParams[name] {
			return match // keep as-is (shouldn't happen after stripping)
		}
		params = append(params, name)
		return "%s"
	})
	return fmtStr, params
}

// snakeToCamel converts snake_case to camelCase.
// e.g. "include_read" -> "includeRead", "board_id" -> "boardId"
func snakeToCamel(s string) string {
	parts := strings.Split(s, "_")
	for i := 1; i < len(parts); i++ {
		if len(parts[i]) > 0 {
			parts[i] = strings.ToUpper(parts[i][:1]) + parts[i][1:]
		}
	}
	return strings.Join(parts, "")
}

// queryParamGoType returns the Go pointer type for a query parameter.
func queryParamGoType(schemaType string) string {
	switch schemaType {
	case "boolean":
		return "*bool"
	case "integer":
		return "*int64"
	default:
		return "*string"
	}
}

// queryParamFormatVerb returns the fmt verb for formatting a query param value.
func queryParamFormatVerb(schemaType string) string {
	switch schemaType {
	case "boolean":
		return "%t"
	case "integer":
		return "%d"
	default:
		return "%s"
	}
}

// paramToGoName converts camelCase param names to Go argument names.
// e.g. "boardId" -> "boardID", "cardNumber" -> "cardNumber"
func paramToGoName(name string) string {
	// Special cases for common ID suffixes
	if strings.HasSuffix(name, "Id") {
		return name[:len(name)-2] + "ID"
	}
	return name
}

// ---------------------------------------------------------------------------
// Request body type handling
// ---------------------------------------------------------------------------

// requestTypeName converts the schema $ref name to the Go type alias name.
// e.g. "CreateBoardRequestContent" -> "CreateBoardRequest"
func requestTypeName(refName string) string {
	// Strip "Content" suffix
	name := strings.TrimSuffix(refName, "Content")
	// Ensure "Request" suffix
	if !strings.HasSuffix(name, "Request") {
		name += "Request"
	}
	return name
}

// ---------------------------------------------------------------------------
// Service definition
// ---------------------------------------------------------------------------

type ServiceDef struct {
	Name       string
	Operations []ParsedOp
}

// ---------------------------------------------------------------------------
// Code generation
// ---------------------------------------------------------------------------

func generateServiceFile(svc ServiceDef) string {
	var buf strings.Builder

	buf.WriteString("// Code generated from openapi.json — DO NOT EDIT.\n")
	buf.WriteString("package fizzy\n\n")

	// Determine what imports we need
	needsFmt := false
	needsJSON := false
	needsGenerated := false

	for _, op := range svc.Operations {
		if op.HasRequestBody || (op.HasResponseData && op.ResponseGoType != "") {
			needsGenerated = true
		}
		// json.RawMessage fallback: HasResponseData but no resolved Go type
		if op.HasResponseData && op.ResponseGoType == "" && op.HTTPMethod != "DELETE" {
			needsJSON = true
		}
		// Check if we need fmt for path formatting
		path := op.Path
		if isAccountScoped(svc.Name) {
			path = stripAccountPrefix(path)
		}
		if strings.Contains(path, "{") {
			needsFmt = true
		}
		// Query params need fmt for Sprintf
		isPaginatedList := op.HasPagination && strings.HasPrefix(
			deriveMethodName(op.OperationID, svc.Name), "List")
		if !isPaginatedList && len(op.QueryParams) > 0 {
			needsFmt = true
		}
	}

	if needsFmt || needsJSON || needsGenerated {
		buf.WriteString("import (\n")
		buf.WriteString("\t\"context\"\n")
		if needsJSON {
			buf.WriteString("\t\"encoding/json\"\n")
		}
		if needsFmt {
			buf.WriteString("\t\"fmt\"\n")
		}
		if needsGenerated {
			buf.WriteString("\n\t\"github.com/basecamp/fizzy-sdk/go/pkg/generated\"\n")
		}
		buf.WriteString(")\n")
	} else {
		buf.WriteString("import (\n")
		buf.WriteString("\t\"context\"\n")
		buf.WriteString(")\n")
	}

	// Sort operations for stable output
	ops := make([]ParsedOp, len(svc.Operations))
	copy(ops, svc.Operations)
	sort.Slice(ops, func(i, j int) bool {
		return ops[i].OperationID < ops[j].OperationID
	})

	for _, op := range ops {
		buf.WriteString("\n")
		buf.WriteString(generateMethod(svc.Name, op))
	}

	return buf.String()
}

func generateMethod(serviceName string, op ParsedOp) string {
	var buf strings.Builder

	methodName := deriveMethodName(op.OperationID, serviceName)
	accountScoped := isAccountScoped(serviceName)

	// Compute the Go path
	path := op.Path
	if accountScoped {
		path = stripAccountPrefix(path)
	}

	// For Devices service: it's on *Client but has {accountId} in path.
	// Keep {accountId} in the path and include it as a parameter.
	skipParams := map[string]bool{}
	if accountScoped {
		skipParams["accountId"] = true
	}

	fmtStr, pathParamNames := goFormatPath(path, skipParams)
	hasFormatParams := len(pathParamNames) > 0

	// Build Go parameter names
	goParams := make([]string, 0, len(pathParamNames)+2)
	for _, p := range pathParamNames {
		goParams = append(goParams, paramToGoName(p))
	}

	// Determine return type and signature
	returnsData := op.HasResponseData
	isDelete := op.HTTPMethod == "DELETE"

	// Overrides: DELETE always returns (*Response, error) for safety
	if isDelete {
		returnsData = false
	}

	// Build method signature
	sigParams := []string{"ctx context.Context"}

	// For paginated List methods, use the path-string pattern.
	// If the paginated list also has path params (e.g. ListComments needs cardNumber),
	// include those params before the path param.
	isPaginatedList := op.HasPagination && strings.HasPrefix(methodName, "List")
	if isPaginatedList {
		for _, gp := range goParams {
			sigParams = append(sigParams, gp+" string")
		}
		sigParams = append(sigParams, "path string")
	} else {
		for _, gp := range goParams {
			sigParams = append(sigParams, gp+" string")
		}
	}

	// Query parameters (only for non-paginated operations; paginated use path string)
	if !isPaginatedList && len(op.QueryParams) > 0 {
		for _, qp := range op.QueryParams {
			sigParams = append(sigParams, qp.GoName+" "+queryParamGoType(qp.SchemaType))
		}
	}

	// Request body parameter
	if op.HasRequestBody && op.BodyRefName != "" {
		reqType := requestTypeName(op.BodyRefName)
		sigParams = append(sigParams, "req *generated."+reqType)
	}

	var returnType string
	if returnsData && op.ResponseGoType != "" {
		if op.ResponseIsList {
			returnType = fmt.Sprintf("([]%s, *Response, error)", op.ResponseGoType)
		} else {
			returnType = fmt.Sprintf("(*%s, *Response, error)", op.ResponseGoType)
		}
	} else if returnsData {
		returnType = "(json.RawMessage, *Response, error)"
	} else {
		returnType = "(*Response, error)"
	}

	receiver := "s *" + serviceName + "Service"

	// Generate doc comment
	buf.WriteString(generateDocComment(methodName, serviceName))

	// Method signature
	fmt.Fprintf(&buf, "func (%s) %s(%s) %s {\n",
		receiver, methodName, strings.Join(sigParams, ", "), returnType)

	// Method body
	if isPaginatedList {
		buf.WriteString(generatePaginatedListBody(op, fmtStr, goParams))
	} else {
		buf.WriteString(generateMethodBody(op, fmtStr, hasFormatParams, goParams, returnsData))
	}

	buf.WriteString("}\n")
	return buf.String()
}

func generateDocComment(methodName, serviceName string) string {
	// Generate a brief doc comment based on the HTTP method and operation
	var action string
	var verb string
	switch {
	case strings.HasPrefix(methodName, "List"):
		action = "returns"
		verb = "List"
	case strings.HasPrefix(methodName, "Get"):
		action = "returns"
		verb = "Get"
	case strings.HasPrefix(methodName, "Create"):
		action = "creates"
		verb = "Create"
	case strings.HasPrefix(methodName, "Update"):
		action = "updates"
		verb = "Update"
	case strings.HasPrefix(methodName, "Delete"):
		action = "deletes"
		verb = "Delete"
	default:
		action = "performs the " + methodName + " operation on"
		verb = ""
	}

	resource := strings.ToLower(serviceName)
	resource = strings.TrimSuffix(resource, "s")

	// If the method name has a suffix beyond the verb (e.g. DeleteImage, GetTray),
	// use that suffix as the resource name for a more specific doc comment.
	// Skip when:
	// - the remainder contains the service resource (e.g. GetMyIdentity, CreateDirectUpload)
	// - the remainder is a top-level resource name (e.g. CreateCard in ReactionsService
	//   creates a reaction, not a card)
	if verb != "" {
		remainder := strings.TrimPrefix(methodName, verb)
		svcSingular := strings.TrimSuffix(serviceName, "s")
		if remainder != "" && !isSimplePlural(remainder, serviceName) &&
			!strings.Contains(remainder, svcSingular) && !isTopLevelResource(remainder) {
			resource = strings.ToLower(remainder[:1]) + remainder[1:]
		}
	}

	article := indefiniteArticle(resource)

	var comment string
	switch {
	case strings.HasPrefix(methodName, "List"):
		comment = fmt.Sprintf("// %s %s %ss.", methodName, action, resource)
	default:
		comment = fmt.Sprintf("// %s %s %s %s.", methodName, action, article, resource)
	}

	return comment + "\n"
}

func generatePaginatedListBody(op ParsedOp, fmtStr string, goParams []string) string {
	var buf strings.Builder

	if len(goParams) > 0 {
		// Paginated list with path params: construct default path with fmt.Sprintf
		fmt.Fprintf(&buf, "\tif path == \"\" {\n\t\tpath = fmt.Sprintf(%q, %s)\n\t}\n",
			fmtStr, strings.Join(goParams, ", "))
	} else {
		fmt.Fprintf(&buf, "\tif path == \"\" {\n\t\tpath = %q\n\t}\n", fmtStr)
	}
	buf.WriteString("\tresp, err := s.client.Get(ctx, path)\n")
	buf.WriteString("\tif err != nil {\n\t\treturn nil, nil, err\n\t}\n")
	buf.WriteString(generateUnmarshalReturn(op))

	return buf.String()
}

func generateUnmarshalReturn(op ParsedOp) string {
	var buf strings.Builder
	if op.ResponseGoType == "" {
		// Fallback to raw return (shouldn't happen for typed ops)
		buf.WriteString("\treturn resp.Data, resp, nil\n")
		return buf.String()
	}
	if op.ResponseIsList {
		elementType := strings.TrimPrefix(op.ResponseGoType, "generated.")
		fmt.Fprintf(&buf, "\tvar result []generated.%s\n", elementType)
		buf.WriteString("\tif err := resp.UnmarshalData(&result); err != nil {\n\t\treturn nil, resp, err\n\t}\n")
		buf.WriteString("\treturn result, resp, nil\n")
	} else {
		fmt.Fprintf(&buf, "\tvar result %s\n", op.ResponseGoType)
		buf.WriteString("\tif err := resp.UnmarshalData(&result); err != nil {\n\t\treturn nil, resp, err\n\t}\n")
		buf.WriteString("\treturn &result, resp, nil\n")
	}
	return buf.String()
}

func generateQueryStringBlock(queryParams []QueryParam) string {
	var buf strings.Builder
	buf.WriteString("\tsep := \"?\"\n")
	for _, qp := range queryParams {
		fmt.Fprintf(&buf, "\tif %s != nil {\n", qp.GoName)
		fmt.Fprintf(&buf, "\t\tpath += fmt.Sprintf(\"%s%s=%s\", sep, *%s)\n",
			"%s", qp.Name, queryParamFormatVerb(qp.SchemaType), qp.GoName)
		buf.WriteString("\t\tsep = \"&\"\n")
		buf.WriteString("\t}\n")
	}
	return buf.String()
}

func generateMethodBody(op ParsedOp, fmtStr string, hasFormatParams bool, goParams []string, returnsData bool) string {
	var buf strings.Builder

	hasQueryParams := len(op.QueryParams) > 0

	// Build path expression
	var pathExpr string
	if hasQueryParams {
		// When query params exist, we need a mutable path variable
		if hasFormatParams {
			args := make([]string, len(goParams))
			copy(args, goParams)
			fmt.Fprintf(&buf, "\tpath := fmt.Sprintf(%q, %s)\n", fmtStr, strings.Join(args, ", "))
		} else {
			fmt.Fprintf(&buf, "\tpath := %q\n", fmtStr)
		}
		buf.WriteString(generateQueryStringBlock(op.QueryParams))
		pathExpr = "path"
	} else if hasFormatParams {
		args := make([]string, len(goParams))
		copy(args, goParams)
		pathExpr = fmt.Sprintf("fmt.Sprintf(%q, %s)", fmtStr, strings.Join(args, ", "))
	} else {
		pathExpr = fmt.Sprintf("%q", fmtStr)
	}

	ctxArg := "ctx"
	if op.NoRetry {
		ctxArg = "WithNoRetry(ctx)"
	}

	switch op.HTTPMethod {
	case "GET":
		fmt.Fprintf(&buf, "\tresp, err := s.client.Get(%s, %s)\n", ctxArg, pathExpr)
		buf.WriteString("\tif err != nil {\n\t\treturn nil, nil, err\n\t}\n")
		buf.WriteString(generateUnmarshalReturn(op))

	case "POST":
		bodyArg := "nil"
		if op.HasRequestBody {
			bodyArg = "req"
		}

		if returnsData {
			fmt.Fprintf(&buf, "\tresp, err := s.client.Post(ctx, %s, %s)\n", pathExpr, bodyArg)
			buf.WriteString("\tif err != nil {\n\t\treturn nil, nil, err\n\t}\n")
			buf.WriteString(generateUnmarshalReturn(op))
		} else {
			fmt.Fprintf(&buf, "\tresp, err := s.client.Post(ctx, %s, %s)\n", pathExpr, bodyArg)
			buf.WriteString("\treturn resp, err\n")
		}

	case "PATCH":
		bodyArg := "nil"
		if op.HasRequestBody {
			bodyArg = "req"
		}
		fmt.Fprintf(&buf, "\tresp, err := s.client.Patch(%s, %s, %s)\n", ctxArg, pathExpr, bodyArg)
		buf.WriteString("\tif err != nil {\n\t\treturn nil, nil, err\n\t}\n")
		buf.WriteString(generateUnmarshalReturn(op))

	case "PUT":
		bodyArg := "nil"
		if op.HasRequestBody {
			bodyArg = "req"
		}
		fmt.Fprintf(&buf, "\tresp, err := s.client.Put(%s, %s, %s)\n", ctxArg, pathExpr, bodyArg)
		buf.WriteString("\tif err != nil {\n\t\treturn nil, nil, err\n\t}\n")
		buf.WriteString(generateUnmarshalReturn(op))

	case "DELETE":
		fmt.Fprintf(&buf, "\treturn s.client.Delete(%s, %s)\n", ctxArg, pathExpr)
	}

	return buf.String()
}

// ---------------------------------------------------------------------------
// Operations registry generation
// ---------------------------------------------------------------------------

func generateOperationsRegistry(services map[string]*ServiceDef) string {
	var buf strings.Builder

	buf.WriteString("// Code generated from openapi.json — DO NOT EDIT.\n")
	buf.WriteString("package fizzy\n\n")
	buf.WriteString("// OperationRegistry maps every OpenAPI operationId to its Go service method.\n")
	buf.WriteString("// The drift check script (scripts/check-service-drift.sh) verifies this\n")
	buf.WriteString("// registry stays in sync with openapi.json.\n")
	buf.WriteString("//\n")
	buf.WriteString("// To update: run 'go run ./cmd/generate-services/' from the go directory.\n")
	buf.WriteString("var OperationRegistry = map[string]string{\n")

	// Sort services for stable output
	serviceNames := make([]string, 0, len(services))
	for name := range services {
		serviceNames = append(serviceNames, name)
	}
	sort.Strings(serviceNames)

	for i, name := range serviceNames {
		svc := services[name]
		if i > 0 {
			buf.WriteString("\n")
		}
		fmt.Fprintf(&buf, "\t// %s\n", name)

		ops := make([]ParsedOp, len(svc.Operations))
		copy(ops, svc.Operations)
		sort.Slice(ops, func(a, b int) bool {
			return ops[a].OperationID < ops[b].OperationID
		})

		for _, op := range ops {
			methodName := deriveMethodName(op.OperationID, name)
			fmt.Fprintf(&buf, "\t%q: %q,\n",
				op.OperationID,
				name+"Service."+methodName)
		}
	}

	buf.WriteString("}\n")
	return buf.String()
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

func main() {
	// Determine paths
	// The generator runs from go/ directory: cd go && go run ./cmd/generate-services/
	// openapi.json and behavior-model.json are in the repo root (one level up)
	openapiPath := filepath.Join("..", "openapi.json")
	behaviorPath := filepath.Join("..", "behavior-model.json")
	outputDir := filepath.Join("pkg", "fizzy")

	data, err := os.ReadFile(openapiPath)
	if err != nil {
		log.Fatalf("reading openapi.json: %v", err)
	}

	var spec OpenAPISpec
	if err := json.Unmarshal(data, &spec); err != nil {
		log.Fatalf("parsing openapi.json: %v", err)
	}

	// Load behavior model to determine which operations disable retry
	behaviorData, err := os.ReadFile(behaviorPath)
	if err != nil {
		log.Fatalf("reading behavior-model.json: %v", err)
	}
	var behaviorModel BehaviorModel
	if err := json.Unmarshal(behaviorData, &behaviorModel); err != nil {
		log.Fatalf("parsing behavior-model.json: %v", err)
	}

	httpMethods := []string{"get", "post", "put", "patch", "delete"}
	services := map[string]*ServiceDef{}

	for path, pathItem := range spec.Paths {
		for _, method := range httpMethods {
			raw, ok := pathItem[method]
			if !ok {
				continue
			}

			var op Operation
			if err := json.Unmarshal(raw, &op); err != nil {
				log.Fatalf("parsing operation at %s %s: %v", method, path, err)
			}

			if op.OperationID == "" {
				continue
			}

			// Parse the operation
			parsed := ParsedOp{
				OperationID: op.OperationID,
				HTTPMethod:  strings.ToUpper(method),
				Path:        path,
			}

			// Path params and query params
			for _, p := range op.Parameters {
				switch p.In {
				case "path":
					parsed.PathParams = append(parsed.PathParams, p.Name)
				case "query":
					parsed.QueryParams = append(parsed.QueryParams, QueryParam{
						Name:       p.Name,
						GoName:     snakeToCamel(p.Name),
						SchemaType: p.Schema.Type,
					})
				}
			}

			// Request body
			if op.RequestBody != nil {
				if jsonContent, ok := op.RequestBody.Content["application/json"]; ok {
					if jsonContent.Schema.Ref != "" {
						parsed.HasRequestBody = true
						parts := strings.Split(jsonContent.Schema.Ref, "/")
						parsed.BodyRefName = parts[len(parts)-1]
					}
				}
			}

			// Response data: check 200/201 for content with schema
			parsed.HasResponseData = false
			for _, code := range []string{"200", "201"} {
				if resp, ok := op.Responses[code]; ok {
					if resp.Content != nil {
						if jsonContent, ok := resp.Content["application/json"]; ok {
							if jsonContent.Schema.Ref != "" {
								parsed.HasResponseData = true
								parsed.ResponseRefName = resolveRef(jsonContent.Schema.Ref)
							}
						}
					}
				}
			}

			// Resolve response type from schema
			if parsed.ResponseRefName != "" {
				parsed.ResponseGoType, parsed.ResponseIsList = responseTypeName(
					parsed.ResponseRefName, spec.Components.Schemas)
			}

			// Pagination
			parsed.HasPagination = op.Pagination != nil

			// NoRetry: non-POST operations with retry_on: null in behavior model
			if parsed.HTTPMethod != "POST" {
				if entry, ok := behaviorModel.Operations[op.OperationID]; ok {
					if string(entry.Retry.RetryOn) == "null" {
						parsed.NoRetry = true
					}
				}
			}

			// Group into service
			svcName := deriveServiceName(op.OperationID)
			if services[svcName] == nil {
				services[svcName] = &ServiceDef{Name: svcName}
			}
			services[svcName].Operations = append(services[svcName].Operations, parsed)
		}
	}

	// Generate service files
	totalOps := 0
	for name, svc := range services {
		code := generateServiceFile(*svc)

		filename := toSnakeCase(name) + "_service.go"
		outPath := filepath.Join(outputDir, filename)

		if err := os.WriteFile(outPath, []byte(code), 0600); err != nil {
			log.Fatalf("writing %s: %v", outPath, err)
		}
		fmt.Printf("Generated %s (%d operations)\n", filename, len(svc.Operations))
		totalOps += len(svc.Operations)
	}

	// Generate operations registry
	registryCode := generateOperationsRegistry(services)
	registryPath := filepath.Join(outputDir, "operations_registry.go")
	if err := os.WriteFile(registryPath, []byte(registryCode), 0600); err != nil {
		log.Fatalf("writing operations_registry.go: %v", err)
	}
	fmt.Printf("Generated operations_registry.go (%d operations)\n", totalOps)

	fmt.Printf("\nGenerated %d services with %d operations total.\n", len(services), totalOps)
}

// isSimplePlural returns true if the remainder is the service resource
// singular or plural (e.g. "Card" for "Cards", "Comments" for "Comments").
func isSimplePlural(remainder, serviceName string) bool {
	sn := strings.ToLower(serviceName)
	r := strings.ToLower(remainder)
	return r == sn || r+"s" == sn || r == strings.TrimSuffix(sn, "s")
}

// isTopLevelResource returns true if the name matches one of the 15 service
// resource names. Used to avoid doc comments like "creates a card" for
// ReactionsService.CreateCard (which creates a reaction, not a card).
func isTopLevelResource(name string) bool {
	resources := map[string]bool{
		"Board": true, "Card": true, "Column": true, "Comment": true,
		"Step": true, "Reaction": true, "Notification": true, "Tag": true,
		"User": true, "Pin": true, "Webhook": true, "Session": true,
		"Device": true, "Upload": true, "Identity": true,
	}
	return resources[name]
}

// indefiniteArticle returns "a" or "an" based on the phonetic start of word.
func indefiniteArticle(word string) string {
	if len(word) == 0 {
		return "a"
	}
	// Words starting with a vowel letter but consonant sound
	lower := strings.ToLower(word)
	if strings.HasPrefix(lower, "uni") || strings.HasPrefix(lower, "use") ||
		strings.HasPrefix(lower, "user") {
		return "a"
	}
	if strings.ContainsRune("aeiou", rune(lower[0])) {
		return "an"
	}
	return "a"
}

// toSnakeCase converts PascalCase to snake_case.
func toSnakeCase(s string) string {
	var result strings.Builder
	for i, r := range s {
		if i > 0 && r >= 'A' && r <= 'Z' {
			result.WriteByte('_')
		}
		result.WriteRune(r)
	}
	return strings.ToLower(result.String())
}
