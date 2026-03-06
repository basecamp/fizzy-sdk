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
	Paths map[string]PathItem `json:"paths"`
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
	Name string `json:"name"`
	In   string `json:"in"`
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
// Parsed operation
// ---------------------------------------------------------------------------

type ParsedOp struct {
	OperationID    string
	HTTPMethod     string // GET, POST, PATCH, DELETE
	Path           string // raw path from spec
	PathParams     []string
	HasRequestBody bool
	BodyRefName    string // e.g. "CreateBoardRequestContent"
	HasResponseData bool
	HasPagination  bool
}

// ---------------------------------------------------------------------------
// Service grouping
// ---------------------------------------------------------------------------

// operationServiceOverrides maps operationId to service name for operations
// whose service cannot be derived from suffix matching.
var operationServiceOverrides = map[string]string{
	"GetMyIdentity":        "Identity",
	"CreateDirectUpload":   "Uploads",
	"RedeemMagicLink":      "Sessions",
	"CompleteSignup":       "Sessions",
	"GetNotificationTray":  "Notifications",
	"BulkReadNotifications": "Notifications",
	"DeleteCardImage":      "Cards",
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
		if op.HasResponseData {
			needsJSON = true
		}
		if op.HasRequestBody {
			needsGenerated = true
		}
		// Check if we need fmt for path formatting
		path := op.Path
		if isAccountScoped(svc.Name) {
			path = stripAccountPrefix(path)
		}
		if strings.Contains(path, "{") {
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

	// Request body parameter
	if op.HasRequestBody && op.BodyRefName != "" {
		reqType := requestTypeName(op.BodyRefName)
		sigParams = append(sigParams, "req *generated."+reqType)
	}

	var returnType string
	if returnsData {
		returnType = "(json.RawMessage, *Response, error)"
	} else {
		returnType = "(*Response, error)"
	}

	receiver := "s *" + serviceName + "Service"

	// Generate doc comment
	buf.WriteString(generateDocComment(methodName, serviceName, op))

	// Method signature
	buf.WriteString(fmt.Sprintf("func (%s) %s(%s) %s {\n",
		receiver, methodName, strings.Join(sigParams, ", "), returnType))

	// Method body
	if isPaginatedList {
		buf.WriteString(generatePaginatedListBody(serviceName, op, fmtStr, goParams))
	} else {
		buf.WriteString(generateMethodBody(serviceName, op, fmtStr, hasFormatParams, goParams, returnsData))
	}

	buf.WriteString("}\n")
	return buf.String()
}

func generateDocComment(methodName, serviceName string, op ParsedOp) string {
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
	if strings.HasSuffix(resource, "s") {
		resource = resource[:len(resource)-1]
	}

	// If the method name has a suffix beyond the verb (e.g. DeleteImage, GetTray),
	// use that suffix as the resource name for a more specific doc comment.
	// Skip when the remainder contains the service resource (e.g. GetMyIdentity,
	// CreateDirectUpload) — those should use the service resource.
	if verb != "" {
		remainder := strings.TrimPrefix(methodName, verb)
		svcSingular := serviceName
		if strings.HasSuffix(svcSingular, "s") {
			svcSingular = svcSingular[:len(svcSingular)-1]
		}
		if remainder != "" && !isSimplePlural(remainder, serviceName) && !strings.Contains(remainder, svcSingular) {
			resource = strings.ToLower(remainder[:1]) + remainder[1:]
		}
	}

	article := "a"
	if len(resource) > 0 && strings.ContainsRune("aeiou", rune(resource[0])) {
		article = "an"
	}

	var comment string
	switch {
	case strings.HasPrefix(methodName, "List"):
		comment = fmt.Sprintf("// %s %s %ss.", methodName, action, resource)
	default:
		comment = fmt.Sprintf("// %s %s %s %s.", methodName, action, article, resource)
	}

	return comment + "\n"
}

func generatePaginatedListBody(serviceName string, op ParsedOp, fmtStr string, goParams []string) string {
	var buf strings.Builder

	if len(goParams) > 0 {
		// Paginated list with path params: construct default path with fmt.Sprintf
		buf.WriteString(fmt.Sprintf("\tif path == \"\" {\n\t\tpath = fmt.Sprintf(%q, %s)\n\t}\n",
			fmtStr, strings.Join(goParams, ", ")))
	} else {
		buf.WriteString(fmt.Sprintf("\tif path == \"\" {\n\t\tpath = %q\n\t}\n", fmtStr))
	}
	buf.WriteString("\tresp, err := s.client.Get(ctx, path)\n")
	buf.WriteString("\tif err != nil {\n\t\treturn nil, nil, err\n\t}\n")
	buf.WriteString("\treturn resp.Data, resp, nil\n")

	return buf.String()
}

func generateMethodBody(serviceName string, op ParsedOp, fmtStr string, hasFormatParams bool, goParams []string, returnsData bool) string {
	var buf strings.Builder

	// Build path expression
	var pathExpr string
	if hasFormatParams {
		args := make([]string, len(goParams))
		for i, p := range goParams {
			args[i] = p
		}
		pathExpr = fmt.Sprintf("fmt.Sprintf(%q, %s)", fmtStr, strings.Join(args, ", "))
	} else {
		pathExpr = fmt.Sprintf("%q", fmtStr)
	}

	switch op.HTTPMethod {
	case "GET":
		buf.WriteString(fmt.Sprintf("\tresp, err := s.client.Get(ctx, %s)\n", pathExpr))
		buf.WriteString("\tif err != nil {\n\t\treturn nil, nil, err\n\t}\n")
		buf.WriteString("\treturn resp.Data, resp, nil\n")

	case "POST":
		bodyArg := "nil"
		if op.HasRequestBody {
			bodyArg = "req"
		}

		if returnsData {
			buf.WriteString(fmt.Sprintf("\tresp, err := s.client.Post(ctx, %s, %s)\n", pathExpr, bodyArg))
			buf.WriteString("\tif err != nil {\n\t\treturn nil, nil, err\n\t}\n")
			buf.WriteString("\treturn resp.Data, resp, nil\n")
		} else {
			buf.WriteString(fmt.Sprintf("\tresp, err := s.client.Post(ctx, %s, %s)\n", pathExpr, bodyArg))
			buf.WriteString("\treturn resp, err\n")
		}

	case "PATCH":
		bodyArg := "nil"
		if op.HasRequestBody {
			bodyArg = "req"
		}
		buf.WriteString(fmt.Sprintf("\tresp, err := s.client.Patch(ctx, %s, %s)\n", pathExpr, bodyArg))
		buf.WriteString("\tif err != nil {\n\t\treturn nil, nil, err\n\t}\n")
		buf.WriteString("\treturn resp.Data, resp, nil\n")

	case "PUT":
		bodyArg := "nil"
		if op.HasRequestBody {
			bodyArg = "req"
		}
		buf.WriteString(fmt.Sprintf("\tresp, err := s.client.Put(ctx, %s, %s)\n", pathExpr, bodyArg))
		buf.WriteString("\tif err != nil {\n\t\treturn nil, nil, err\n\t}\n")
		buf.WriteString("\treturn resp.Data, resp, nil\n")

	case "DELETE":
		buf.WriteString(fmt.Sprintf("\treturn s.client.Delete(ctx, %s)\n", pathExpr))
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
	buf.WriteString("// When adding a new API operation: add the operationId here and implement\n")
	buf.WriteString("// the corresponding service method.\n")
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
		buf.WriteString(fmt.Sprintf("\t// %s\n", name))

		ops := make([]ParsedOp, len(svc.Operations))
		copy(ops, svc.Operations)
		sort.Slice(ops, func(a, b int) bool {
			return ops[a].OperationID < ops[b].OperationID
		})

		for _, op := range ops {
			methodName := deriveMethodName(op.OperationID, name)
			buf.WriteString(fmt.Sprintf("\t%q: %q,\n",
				op.OperationID,
				name+"Service."+methodName))
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
	// openapi.json is in the repo root (one level up)
	openapiPath := filepath.Join("..", "openapi.json")
	outputDir := filepath.Join("pkg", "fizzy")

	data, err := os.ReadFile(openapiPath)
	if err != nil {
		log.Fatalf("reading openapi.json: %v", err)
	}

	var spec OpenAPISpec
	if err := json.Unmarshal(data, &spec); err != nil {
		log.Fatalf("parsing openapi.json: %v", err)
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

			// Path params (excluding accountId for service method params)
			for _, p := range op.Parameters {
				if p.In == "path" {
					parsed.PathParams = append(parsed.PathParams, p.Name)
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
							}
						}
					}
				}
			}

			// Pagination
			parsed.HasPagination = op.Pagination != nil

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

		if err := os.WriteFile(outPath, []byte(code), 0644); err != nil {
			log.Fatalf("writing %s: %v", outPath, err)
		}
		fmt.Printf("Generated %s (%d operations)\n", filename, len(svc.Operations))
		totalOps += len(svc.Operations)
	}

	// Generate operations registry
	registryCode := generateOperationsRegistry(services)
	registryPath := filepath.Join(outputDir, "operations_registry.go")
	if err := os.WriteFile(registryPath, []byte(registryCode), 0644); err != nil {
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
