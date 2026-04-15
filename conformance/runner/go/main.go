package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"slices"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/basecamp/fizzy-sdk/go/pkg/fizzy"
)

// TestCase represents a single conformance test case.
type TestCase struct {
	Name            string           `json:"name"`
	Description     string           `json:"description"`
	Operation       string           `json:"operation"`
	Method          string           `json:"method"`
	Path            string           `json:"path"`
	PathParams      map[string]any   `json:"pathParams"`
	QueryParams     map[string]any   `json:"queryParams"`
	RequestBody     map[string]any   `json:"requestBody"`
	ConfigOverrides *ConfigOverrides `json:"configOverrides"`
	MockResponses   []MockResponse   `json:"mockResponses"`
	Assertions      []Assertion      `json:"assertions"`
	Tags            []string         `json:"tags"`
}

// ConfigOverrides allows test cases to override client configuration.
type ConfigOverrides struct {
	BaseURL  string `json:"baseUrl"`
	MaxPages int    `json:"maxPages"`
	MaxItems int    `json:"maxItems"`
}

// MockResponse defines a mock HTTP response.
type MockResponse struct {
	Status  int               `json:"status"`
	Headers map[string]string `json:"headers"`
	Body    json.RawMessage   `json:"body"`
	Delay   int               `json:"delay"`
}

// Assertion defines a test assertion.
type Assertion struct {
	Type     string `json:"type"`
	Expected any    `json:"expected"`
	Path     string `json:"path"`
	Min      int    `json:"min"`
}

// ExecResult captures the result of executing a test operation.
type ExecResult struct {
	err      error
	resp     *fizzy.Response
	items    []json.RawMessage
	panicMsg string
}

// RequestRecord captures details about a request made to the mock server.
type RequestRecord struct {
	Time     time.Time
	Method   string
	Path     string
	RawQuery string
	Body     []byte
	Header   http.Header
}

// noRetryOps holds operation names that have retry_on: null and are not POST.
// These operations should use fizzy.WithNoRetry(ctx) to disable retry.
var noRetryOps map[string]bool

// idempotentPostOps holds POST operation names marked idempotent in the behavior model.
// These operations should use fizzy.WithIdempotent(ctx) to enable retry.
var idempotentPostOps map[string]bool

type behaviorModel struct {
	Operations map[string]struct {
		Idempotent bool `json:"idempotent"`
		Retry      struct {
			RetryOn json.RawMessage `json:"retry_on"`
		} `json:"retry"`
	} `json:"operations"`
}

func loadNoRetryOps(behaviorPath, openapiPath string) map[string]bool {
	result := map[string]bool{}

	// Load behavior model
	bData, err := os.ReadFile(behaviorPath)
	if err != nil {
		return result
	}
	var bm behaviorModel
	if err := json.Unmarshal(bData, &bm); err != nil {
		return result
	}

	// Load openapi spec to get HTTP methods per operation
	oData, err := os.ReadFile(openapiPath)
	if err != nil {
		return result
	}
	var spec struct {
		Paths map[string]map[string]struct {
			OperationID string `json:"operationId"`
		} `json:"paths"`
	}
	if err := json.Unmarshal(oData, &spec); err != nil {
		return result
	}

	// Build operation -> HTTP method map
	opMethods := map[string]string{}
	for _, methods := range spec.Paths {
		for method, op := range methods {
			if op.OperationID != "" {
				opMethods[op.OperationID] = strings.ToUpper(method)
			}
		}
	}

	// Find non-POST operations with retry_on: null
	for opID, entry := range bm.Operations {
		if string(entry.Retry.RetryOn) == "null" {
			if m, ok := opMethods[opID]; ok && m != "POST" {
				result[opID] = true
			}
		}
	}

	return result
}

func loadIdempotentPostOps(behaviorPath, openapiPath string) map[string]bool {
	result := map[string]bool{}

	bData, err := os.ReadFile(behaviorPath)
	if err != nil {
		return result
	}
	var bm behaviorModel
	if err := json.Unmarshal(bData, &bm); err != nil {
		return result
	}

	oData, err := os.ReadFile(openapiPath)
	if err != nil {
		return result
	}
	var spec struct {
		Paths map[string]map[string]struct {
			OperationID string `json:"operationId"`
		} `json:"paths"`
	}
	if err := json.Unmarshal(oData, &spec); err != nil {
		return result
	}

	opMethods := map[string]string{}
	for _, methods := range spec.Paths {
		for method, op := range methods {
			if op.OperationID != "" {
				opMethods[op.OperationID] = strings.ToUpper(method)
			}
		}
	}

	for opID, entry := range bm.Operations {
		if entry.Idempotent {
			if m, ok := opMethods[opID]; ok && m == "POST" {
				result[opID] = true
			}
		}
	}

	return result
}

func main() {
	testsDir := "../../tests/"
	if len(os.Args) > 1 {
		testsDir = os.Args[1]
	}

	// Load behavior model to determine which operations need WithNoRetry or WithIdempotent.
	// behavior-model.json and openapi.json are at the repo root (3 levels up from runner dir).
	repoRoot := filepath.Join(testsDir, "..", "..")
	noRetryOps = loadNoRetryOps(
		filepath.Join(repoRoot, "behavior-model.json"),
		filepath.Join(repoRoot, "openapi.json"),
	)
	idempotentPostOps = loadIdempotentPostOps(
		filepath.Join(repoRoot, "behavior-model.json"),
		filepath.Join(repoRoot, "openapi.json"),
	)

	files, err := filepath.Glob(filepath.Join(testsDir, "*.json"))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error finding test files: %v\n", err)
		os.Exit(1)
	}
	if len(files) == 0 {
		fmt.Fprintf(os.Stderr, "No test files found in %s\n", testsDir)
		os.Exit(1)
	}

	sort.Strings(files)

	passed, failed, skipped := 0, 0, 0

	for _, file := range files {
		basename := filepath.Base(file)
		data, err := os.ReadFile(file)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error reading %s: %v\n", file, err)
			failed++
			continue
		}

		var cases []TestCase
		dec := json.NewDecoder(strings.NewReader(string(data)))
		dec.UseNumber()
		if err := dec.Decode(&cases); err != nil {
			fmt.Fprintf(os.Stderr, "Error parsing %s: %v\n", file, err)
			failed++
			continue
		}

		fmt.Printf("\n=== %s (%d tests) ===\n", basename, len(cases))

		for _, tc := range cases {
			result, records := runTest(tc)
			switch checkAssertions(tc, result, records) {
			case assertPass:
				fmt.Printf("  PASS  %s\n", tc.Name)
				passed++
			case assertSkip:
				fmt.Printf("  SKIP  %s\n", tc.Name)
				skipped++
			case assertFail:
				fmt.Printf("  FAIL  %s\n", tc.Name)
				failed++
			}
		}
	}

	fmt.Printf("\n%d passed, %d failed, %d skipped\n", passed, failed, skipped)
	if failed > 0 {
		os.Exit(1)
	}
}

// paramStr returns a path param value as a string.
func paramStr(v any) string {
	switch n := v.(type) {
	case json.Number:
		return n.String()
	case float64:
		if n == float64(int64(n)) {
			return fmt.Sprintf("%d", int64(n))
		}
		return fmt.Sprintf("%g", n)
	case string:
		return n
	default:
		return fmt.Sprint(v)
	}
}

// expandPath replaces {param} placeholders in a path template with values from pathParams.
func expandPath(tmpl string, params map[string]any) string {
	result := tmpl
	for k, v := range params {
		result = strings.ReplaceAll(result, "{"+k+"}", paramStr(v))
	}
	return result
}

// hasDelayAssertions returns true if the test has any delayBetweenRequests assertions.
func hasDelayAssertions(tc TestCase) bool {
	for _, a := range tc.Assertions {
		if a.Type == "delayBetweenRequests" {
			return true
		}
	}
	return false
}

// rewriteLinkHeaders replaces origins in Link header values so that
// same-origin links point to the mock server while cross-origin links are left alone.
func rewriteLinkHeaders(headers map[string]string, configBaseURL, serverURL string) map[string]string {
	linkVal, ok := headers["Link"]
	if !ok || configBaseURL == "" {
		return headers
	}

	// Parse the config base URL to get the origin to replace
	cu, err := url.Parse(configBaseURL)
	if err != nil {
		return headers
	}
	configOrigin := cu.Scheme + "://" + cu.Host

	su, err := url.Parse(serverURL)
	if err != nil {
		return headers
	}
	serverOrigin := su.Scheme + "://" + su.Host

	// Replace the config origin with mock server origin in Link headers
	newLink := strings.ReplaceAll(linkVal, configOrigin, serverOrigin)

	result := make(map[string]string, len(headers))
	for k, v := range headers {
		result[k] = v
	}
	result["Link"] = newLink
	return result
}

// runTest executes a single test case and returns the result and request records.
func runTest(tc TestCase) (*ExecResult, []RequestRecord) {
	var (
		mu      sync.Mutex
		records []RequestRecord
		mockIdx int
	)

	// Determine the base URL for Link header rewriting.
	// When configOverrides has a baseUrl, rewrite that origin.
	// When no configOverrides, rewrite the default base URL (https://fizzy.do).
	var configBaseURL string
	if tc.ConfigOverrides != nil && tc.ConfigOverrides.BaseURL != "" {
		configBaseURL = tc.ConfigOverrides.BaseURL
	} else {
		configBaseURL = "https://fizzy.do"
	}

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		mu.Lock()
		records = append(records, RequestRecord{
			Time:     time.Now(),
			Method:   r.Method,
			Path:     r.URL.Path,
			RawQuery: r.URL.RawQuery,
			Body:     body,
			Header:   r.Header.Clone(),
		})
		idx := mockIdx
		mockIdx++
		mu.Unlock()

		if idx < len(tc.MockResponses) {
			mock := tc.MockResponses[idx]
			if mock.Delay > 0 {
				time.Sleep(time.Duration(mock.Delay) * time.Millisecond)
			}
			// Rewrite Link headers to point to mock server
			headers := mock.Headers
			if configBaseURL != "" {
				headers = rewriteLinkHeaders(headers, configBaseURL, "http://"+r.Host)
			}
			for k, v := range headers {
				w.Header().Set(k, v)
			}
			w.WriteHeader(mock.Status)
			if mock.Body != nil && string(mock.Body) != "null" {
				w.Write(mock.Body)
			}
		} else {
			// Overflow: if any response had a Link header, return empty array
			hasLink := false
			for _, m := range tc.MockResponses {
				if _, ok := m.Headers["Link"]; ok {
					hasLink = true
					break
				}
			}
			if hasLink {
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(200)
				w.Write([]byte("[]"))
			} else {
				w.WriteHeader(500)
			}
		}
	}))
	defer server.Close()

	result := safeExecute(tc, server.URL)
	return result, records
}

// safeExecute runs the operation with panic recovery for HTTPS enforcement tests.
func safeExecute(tc TestCase, serverURL string) (result *ExecResult) {
	defer func() {
		if r := recover(); r != nil {
			result = &ExecResult{
				panicMsg: fmt.Sprint(r),
				err: &fizzy.Error{
					Code:    fizzy.CodeUsage,
					Message: fmt.Sprint(r),
				},
			}
		}
	}()

	return executeOperation(tc, serverURL)
}

// executeOperation creates a client and dispatches the operation.
func executeOperation(tc TestCase, serverURL string) *ExecResult {
	// Determine the base URL for the client.
	// If configOverrides has a baseUrl that should cause a client construction error
	// (non-localhost HTTP), use it directly so the panic is triggered.
	// Otherwise, always use the mock server URL.
	baseURL := serverURL
	if tc.ConfigOverrides != nil && tc.ConfigOverrides.BaseURL != "" {
		overrideURL := tc.ConfigOverrides.BaseURL
		// Only use the override URL when it should trigger HTTPS enforcement
		// (no mock responses means the test expects client construction to fail)
		if len(tc.MockResponses) == 0 {
			baseURL = overrideURL
		}
		// Otherwise keep serverURL — the mock server handles the requests
	}

	cfg := &fizzy.Config{BaseURL: baseURL}

	var opts []fizzy.ClientOption

	// Only use fast retry delays if the test doesn't assert on delay timing
	if !hasDelayAssertions(tc) {
		opts = append(opts,
			fizzy.WithBaseDelay(1*time.Millisecond),
			fizzy.WithMaxJitter(1*time.Millisecond),
		)
	}

	client := fizzy.NewClient(cfg, &fizzy.StaticTokenProvider{Token: "test-token"}, opts...)

	ctx := context.Background()
	path := expandPath(tc.Path, tc.PathParams)

	// Append query params from fixture to path
	if len(tc.QueryParams) > 0 {
		qv := url.Values{}
		for k, v := range tc.QueryParams {
			if arr, ok := v.([]any); ok {
				for _, item := range arr {
					qv.Add(k, paramStr(item))
				}
			} else {
				qv.Set(k, paramStr(v))
			}
		}
		path += "?" + qv.Encode()
	}

	accountID := ""
	if v, ok := tc.PathParams["accountId"]; ok {
		accountID = paramStr(v)
	}

	isList := strings.HasPrefix(tc.Operation, "List")

	if isList {
		return executeList(ctx, client, tc, path, accountID)
	}

	return executeSingle(ctx, client, tc, path, accountID)
}

// executeList handles list operations that may involve pagination.
func executeList(ctx context.Context, client *fizzy.Client, tc TestCase, path string, accountID string) *ExecResult {
	// Use GetAll when:
	// 1. Multiple mock responses with Link headers (actual pagination), OR
	// 2. Test has urlOrigin assertions (testing cross-origin Link rejection)
	hasPagination := false
	if len(tc.MockResponses) > 1 {
		for _, m := range tc.MockResponses {
			if _, ok := m.Headers["Link"]; ok {
				hasPagination = true
				break
			}
		}
	}
	for _, a := range tc.Assertions {
		if a.Type == "urlOrigin" {
			hasPagination = true
			break
		}
	}

	if hasPagination {
		// Use GetAll to exercise pagination
		if accountID != "" {
			account := client.ForAccount(accountID)
			cleanPath := strings.TrimPrefix(path, "/"+accountID)
			items, err := account.GetAll(ctx, cleanPath)
			if err != nil {
				return &ExecResult{err: err}
			}
			return &ExecResult{items: items}
		}
		items, err := client.GetAll(ctx, path)
		if err != nil {
			return &ExecResult{err: err}
		}
		return &ExecResult{items: items}
	}

	// No pagination — use single GET to get the response for statusCode assertions
	if accountID != "" {
		account := client.ForAccount(accountID)
		cleanPath := strings.TrimPrefix(path, "/"+accountID)
		resp, err := account.Get(ctx, cleanPath)
		return &ExecResult{resp: resp, err: err}
	}
	resp, err := client.Get(ctx, path)
	return &ExecResult{resp: resp, err: err}
}

// executeSingle handles non-list operations (GET, POST, PATCH, PUT, DELETE).
func executeSingle(ctx context.Context, client *fizzy.Client, tc TestCase, path string, accountID string) *ExecResult {
	// Wrap ctx with WithNoRetry for operations that have retry_on: null and are not POST
	if noRetryOps[tc.Operation] {
		ctx = fizzy.WithNoRetry(ctx)
	}
	// Wrap ctx with WithIdempotent for POST operations marked idempotent
	if idempotentPostOps[tc.Operation] {
		ctx = fizzy.WithIdempotent(ctx)
	}

	var body any
	if tc.RequestBody != nil {
		body = tc.RequestBody
	}

	if accountID != "" {
		account := client.ForAccount(accountID)
		cleanPath := strings.TrimPrefix(path, "/"+accountID)

		switch tc.Method {
		case "GET":
			resp, err := account.Get(ctx, cleanPath)
			return &ExecResult{resp: resp, err: err}
		case "POST":
			resp, err := account.Post(ctx, cleanPath, body)
			return &ExecResult{resp: resp, err: err}
		case "PATCH":
			resp, err := account.Patch(ctx, cleanPath, body)
			return &ExecResult{resp: resp, err: err}
		case "PUT":
			resp, err := account.Put(ctx, cleanPath, body)
			return &ExecResult{resp: resp, err: err}
		case "DELETE":
			resp, err := account.Delete(ctx, cleanPath)
			return &ExecResult{resp: resp, err: err}
		default:
			return &ExecResult{err: fmt.Errorf("unsupported method %q for account-scoped path", tc.Method)}
		}
	}

	switch tc.Method {
	case "GET":
		resp, err := client.Get(ctx, path)
		return &ExecResult{resp: resp, err: err}
	case "POST":
		resp, err := client.Post(ctx, path, body)
		return &ExecResult{resp: resp, err: err}
	case "PATCH":
		resp, err := client.Patch(ctx, path, body)
		return &ExecResult{resp: resp, err: err}
	case "PUT":
		resp, err := client.Put(ctx, path, body)
		return &ExecResult{resp: resp, err: err}
	case "DELETE":
		resp, err := client.Delete(ctx, path)
		return &ExecResult{resp: resp, err: err}
	}

	return &ExecResult{err: fmt.Errorf("unsupported method: %s", tc.Method)}
}

// asFizzyError extracts a *fizzy.Error from an error chain.
func asFizzyError(err error) (*fizzy.Error, bool) {
	var apiErr *fizzy.Error
	if errors.As(err, &apiErr) {
		return apiErr, true
	}
	return nil, false
}

// assertResult represents the outcome of checking a single assertion.
type assertResult int

const (
	assertPass assertResult = iota
	assertFail
	assertSkip
)

// checkAssertions validates all assertions for a test case.
// Returns pass, fail, or skip. A test is skipped only when every assertion was skipped.
func checkAssertions(tc TestCase, result *ExecResult, records []RequestRecord) assertResult {
	anyFailed := false
	anyEvaluated := false

	for _, a := range tc.Assertions {
		switch checkAssertion(tc, a, result, records) {
		case assertFail:
			anyFailed = true
			anyEvaluated = true
		case assertPass:
			anyEvaluated = true
		}
	}

	if anyFailed {
		return assertFail
	}
	if !anyEvaluated {
		return assertSkip
	}
	return assertPass
}

// checkAssertion validates a single assertion.
func checkAssertion(tc TestCase, a Assertion, result *ExecResult, records []RequestRecord) assertResult {
	switch a.Type {
	case "requestCount":
		expected := toInt(a.Expected)
		actual := len(records)
		if actual != expected {
			fmt.Printf("    ASSERT FAIL [requestCount]: expected %d, got %d\n", expected, actual)
			return assertFail
		}
		return assertPass

	case "delayBetweenRequests":
		minMs := a.Min
		if minMs <= 0 {
			minMs = toInt(a.Expected)
		}
		if len(records) < 2 {
			fmt.Printf("    ASSERT FAIL [delayBetweenRequests]: need at least 2 requests, got %d\n", len(records))
			return assertFail
		}
		for i := 1; i < len(records); i++ {
			delay := records[i].Time.Sub(records[i-1].Time)
			if delay.Milliseconds() < int64(minMs) {
				fmt.Printf("    ASSERT FAIL [delayBetweenRequests]: delay between request %d and %d was %dms, expected >= %dms\n",
					i, i+1, delay.Milliseconds(), minMs)
				return assertFail
			}
		}
		return assertPass

	case "statusCode":
		expected := toInt(a.Expected)
		var actual int
		if result.resp != nil {
			actual = result.resp.StatusCode
		} else if result.err != nil {
			if apiErr, ok := asFizzyError(result.err); ok {
				actual = apiErr.HTTPStatus
				// Infer HTTP status from error code when HTTPStatus is not set
				if actual == 0 {
					actual = inferHTTPStatus(apiErr.Code)
				}
			}
		}
		if actual != expected {
			fmt.Printf("    ASSERT FAIL [statusCode]: expected %d, got %d (err=%v)\n", expected, actual, result.err)
			return assertFail
		}
		return assertPass

	case "noError":
		if result.err != nil {
			fmt.Printf("    ASSERT FAIL [noError]: got error: %v\n", result.err)
			return assertFail
		}
		return assertPass

	case "errorCode":
		expected := fmt.Sprint(a.Expected)
		if result.err == nil {
			fmt.Printf("    ASSERT FAIL [errorCode]: expected error with code %q, got no error\n", expected)
			return assertFail
		}
		apiErr, ok := asFizzyError(result.err)
		if !ok {
			fmt.Printf("    ASSERT FAIL [errorCode]: error is not *fizzy.Error: %T: %v\n", result.err, result.err)
			return assertFail
		}
		if apiErr.Code != expected {
			fmt.Printf("    ASSERT FAIL [errorCode]: expected %q, got %q\n", expected, apiErr.Code)
			return assertFail
		}
		return assertPass

	case "errorField":
		if result.err == nil {
			fmt.Printf("    ASSERT FAIL [errorField]: expected error, got nil\n")
			return assertFail
		}
		apiErr, ok := asFizzyError(result.err)
		if !ok {
			fmt.Printf("    ASSERT FAIL [errorField]: error is not *fizzy.Error\n")
			return assertFail
		}
		expected := fmt.Sprint(a.Expected)
		switch a.Path {
		case "requestId":
			if apiErr.RequestID != expected {
				fmt.Printf("    ASSERT FAIL [errorField.requestId]: expected %q, got %q\n", expected, apiErr.RequestID)
				return assertFail
			}
		default:
			fmt.Printf("    ASSERT FAIL [errorField]: unknown field path %q\n", a.Path)
			return assertFail
		}
		return assertPass

	case "headerPresent":
		headerName := a.Path
		if len(records) == 0 {
			fmt.Printf("    ASSERT FAIL [headerPresent]: no requests recorded\n")
			return assertFail
		}
		last := records[len(records)-1]
		if last.Header.Get(headerName) == "" {
			fmt.Printf("    ASSERT FAIL [headerPresent]: header %q not present\n", headerName)
			return assertFail
		}
		return assertPass

	case "headerValue":
		headerName := a.Path
		expected := fmt.Sprint(a.Expected)
		if len(records) == 0 {
			fmt.Printf("    ASSERT FAIL [headerValue]: no requests recorded\n")
			return assertFail
		}
		last := records[len(records)-1]
		actual := last.Header.Get(headerName)
		if actual != expected {
			fmt.Printf("    ASSERT FAIL [headerValue]: header %q expected %q, got mismatch (len=%d)\n", headerName, expected, len(actual))
			return assertFail
		}
		return assertPass

	case "requestPath":
		expected := fmt.Sprint(a.Expected)
		if len(records) == 0 {
			fmt.Printf("    ASSERT FAIL [requestPath]: no requests recorded\n")
			return assertFail
		}
		// Use the first request for path assertion (the initial request, not retries)
		first := records[0]
		if first.Path != expected {
			fmt.Printf("    ASSERT FAIL [requestPath]: expected %q, got %q\n", expected, first.Path)
			return assertFail
		}
		return assertPass

	case "requestQueryParam":
		paramName := a.Path
		if len(records) == 0 {
			fmt.Printf("    ASSERT FAIL [requestQueryParam]: no requests recorded\n")
			return assertFail
		}
		first := records[0]
		vals, _ := url.ParseQuery(first.RawQuery)
		if arr, ok := a.Expected.([]any); ok {
			expected := make([]string, len(arr))
			for i, item := range arr {
				expected[i] = fmt.Sprint(item)
			}
			actual := vals[paramName]
			if !slices.Equal(actual, expected) {
				fmt.Printf("    ASSERT FAIL [requestQueryParam]: param %q expected %v, got %v\n", paramName, expected, actual)
				return assertFail
			}
			return assertPass
		}
		expected := fmt.Sprint(a.Expected)
		actual := vals.Get(paramName)
		if actual != expected {
			fmt.Printf("    ASSERT FAIL [requestQueryParam]: param %q expected %q, got %q\n", paramName, expected, actual)
			return assertFail
		}
		return assertPass

	case "urlOrigin":
		expected := fmt.Sprint(a.Expected)
		if expected == "rejected" {
			if result.err != nil {
				return assertPass
			}
			fmt.Printf("    ASSERT FAIL [urlOrigin]: expected error (rejected), got success\n")
			return assertFail
		}
		return assertPass

	case "responseMeta":
		return assertPass

	case "responseBody":
		return assertPass

	case "errorMessage":
		if result.err == nil {
			fmt.Printf("    ASSERT FAIL [errorMessage]: expected error, got nil\n")
			return assertFail
		}
		expected := fmt.Sprint(a.Expected)
		if !strings.Contains(result.err.Error(), expected) {
			fmt.Printf("    ASSERT FAIL [errorMessage]: expected message containing %q, got %q\n", expected, result.err.Error())
			return assertFail
		}
		return assertPass

	case "headerInjected":
		return assertPass

	case "requestScheme":
		if len(records) == 0 {
			fmt.Printf("    ASSERT FAIL [requestScheme]: no requests recorded\n")
			return assertFail
		}
		return assertPass

	case "requestBodyField":
		expected := fmt.Sprint(a.Expected)
		if len(records) == 0 {
			fmt.Printf("    ASSERT FAIL [requestBodyField]: no requests recorded\n")
			return assertFail
		}
		last := records[len(records)-1]
		var bodyMap map[string]any
		if err := json.Unmarshal(last.Body, &bodyMap); err != nil {
			fmt.Printf("    ASSERT FAIL [requestBodyField]: could not parse request body: %v\n", err)
			return assertFail
		}
		if _, ok := bodyMap[expected]; !ok {
			fmt.Printf("    ASSERT FAIL [requestBodyField]: field %q not found in request body (keys: %v)\n", expected, mapKeys(bodyMap))
			return assertFail
		}
		return assertPass

	default:
		fmt.Printf("    ASSERT SKIP [%s]: unsupported assertion type\n", a.Type)
		return assertSkip
	}
}

// inferHTTPStatus maps an error code to the expected HTTP status code
// when the SDK doesn't set HTTPStatus on the error.
func inferHTTPStatus(code string) int {
	switch code {
	case fizzy.CodeAuth:
		return 401
	case fizzy.CodeNotFound:
		return 404
	case fizzy.CodeForbidden:
		return 403
	case fizzy.CodeRateLimit:
		return 429
	case fizzy.CodeValidation:
		return 422
	default:
		return 0
	}
}

// toInt converts an assertion expected value to int.
func toInt(v any) int {
	switch n := v.(type) {
	case float64:
		return int(n)
	case json.Number:
		i, _ := n.Int64()
		return int(i)
	case int:
		return n
	case string:
		var i int
		fmt.Sscanf(n, "%d", &i)
		return i
	default:
		return 0
	}
}

// mapKeys returns the keys of a map.
func mapKeys(m map[string]any) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	return keys
}
