package fizzy

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"
)

// DefaultUserAgent is the default User-Agent header value.
const DefaultUserAgent = "fizzy-sdk-go/" + Version + " (api:" + APIVersion + ")"

// Client is an HTTP client for the Fizzy API.
// Client holds shared resources and is used to create AccountClient instances
// for specific Fizzy accounts via the ForAccount method.
//
// Client is safe for concurrent use after construction. Do not modify
// the Config after the client is in use by multiple goroutines.
type Client struct {
	httpClient    *http.Client
	tokenProvider TokenProvider
	authStrategy  AuthStrategy
	cfg           *Config
	cache         *Cache
	userAgent     string
	logger        *slog.Logger
	httpOpts      HTTPOptions
	hooks         Hooks

	// Account-independent services
	sessionsMu sync.Mutex
	sessions   *SessionsService
	devicesMu  sync.Mutex
	devices    *DevicesService
	identityMu sync.Mutex
	identity   *IdentityService
}

// AccountClient is an HTTP client bound to a specific Fizzy account.
// Create an AccountClient using Client.ForAccount(accountID).
// AccountClient is safe for concurrent use.
//
// The Fizzy API requires an account ID in the URL path. AccountClient shares
// the parent Client's generated API client and HTTP resources. Creating
// multiple AccountClients via ForAccount is lightweight.
type AccountClient struct {
	parent    *Client
	accountID string
	mu        sync.Mutex // protects lazy service initialization

	// Services (lazy-initialized, protected by mu)
	boards        *BoardsService
	columns       *ColumnsService
	cards         *CardsService
	comments      *CommentsService
	steps         *StepsService
	reactions     *ReactionsService
	notifications *NotificationsService
	tags          *TagsService
	users         *UsersService
	pins          *PinsService
	uploads       *UploadsService
	webhooks      *WebhooksService
}

// Response wraps an API response.
type Response struct {
	Data       json.RawMessage
	StatusCode int
	Headers    http.Header
	FromCache  bool
}

// UnmarshalData unmarshals the response data into the given value.
func (r *Response) UnmarshalData(v any) error {
	return json.Unmarshal(r.Data, v)
}

// ClientOption configures a Client.
type ClientOption func(*Client)

// WithHTTPClient sets a custom HTTP client.
func WithHTTPClient(c *http.Client) ClientOption {
	return func(client *Client) {
		client.httpClient = c
	}
}

// WithUserAgent sets the User-Agent header.
func WithUserAgent(ua string) ClientOption {
	return func(client *Client) {
		client.userAgent = ua
	}
}

// WithLogger sets a custom slog logger for debug output.
func WithLogger(l *slog.Logger) ClientOption {
	return func(client *Client) {
		if l != nil {
			client.logger = l
		}
	}
}

// WithCache sets a custom cache.
func WithCache(cache *Cache) ClientOption {
	return func(client *Client) {
		client.cache = cache
	}
}

// WithAuthStrategy sets a custom authentication strategy.
// The default strategy is BearerAuth. Use CookieAuth for session-based auth.
func WithAuthStrategy(strategy AuthStrategy) ClientOption {
	return func(client *Client) {
		client.authStrategy = strategy
	}
}

// NewClient creates a new API client with spec-driven defaults.
//
// The client automatically:
//   - Retries idempotent requests (GET/PUT/PATCH/DELETE) with exponential backoff
//   - Does NOT retry POST on 429/5xx (to avoid duplicating data)
//   - Respects Retry-After headers on 429 responses
//   - Follows pagination via Link headers
func NewClient(cfg *Config, tokenProvider TokenProvider, opts ...ClientOption) *Client {
	cfgCopy := *cfg
	c := &Client{
		tokenProvider: tokenProvider,
		cfg:           &cfgCopy,
		userAgent:     DefaultUserAgent,
		logger:        slog.New(discardHandler{}),
		hooks:         NoopHooks{},
		httpOpts:      DefaultHTTPOptions(),
	}

	for _, opt := range opts {
		opt(c)
	}

	// Default to BearerAuth if no custom auth strategy was provided
	if c.authStrategy == nil {
		c.authStrategy = &BearerAuth{TokenProvider: c.tokenProvider}
	}

	transport := c.httpOpts.Transport
	if transport == nil {
		transport = newDefaultTransport()
	}

	transport = &loggingTransport{inner: transport, client: c}

	c.httpClient = &http.Client{
		Timeout:   c.httpOpts.Timeout,
		Transport: transport,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			if len(via) >= 10 {
				return fmt.Errorf("stopped after 10 redirects")
			}
			if len(via) > 0 && !isSameOrigin(req.URL.String(), via[0].URL.String()) {
				req.Header.Del("Authorization")
				req.Header.Del("Cookie")
			}
			return nil
		},
	}

	// Validate configuration
	if c.cfg.BaseURL != "" && !isLocalhost(c.cfg.BaseURL) {
		if err := requireHTTPS(c.cfg.BaseURL); err != nil {
			panic("fizzy: base URL must use HTTPS: " + c.cfg.BaseURL)
		}
	}
	if c.httpOpts.Timeout <= 0 {
		panic("fizzy: timeout must be positive")
	}
	if c.httpOpts.MaxRetries < 0 {
		panic("fizzy: max retries must be non-negative")
	}
	if c.httpOpts.MaxPages <= 0 {
		panic("fizzy: max pages must be positive")
	}

	// Initialize cache if enabled and not overridden
	if c.cache == nil && cfg.CacheEnabled {
		c.cache = NewCache(cfg.CacheDir)
	}

	return c
}

// ForAccount returns an AccountClient bound to the specified Fizzy account.
// The accountID can be a numeric ID or an account slug. ForAccount panics if
// the accountID is empty.
func (c *Client) ForAccount(accountID string) *AccountClient {
	if accountID == "" {
		panic("fizzy: ForAccount requires non-empty account ID")
	}

	return &AccountClient{
		parent:    c,
		accountID: accountID,
	}
}

// AccountID returns the account ID this client is bound to.
func (ac *AccountClient) AccountID() string {
	return ac.accountID
}

// Get performs an account-scoped GET request.
func (ac *AccountClient) Get(ctx context.Context, path string) (*Response, error) {
	return ac.parent.doRequest(ctx, "GET", ac.accountPath(path), nil)
}

// Post performs an account-scoped POST request with a JSON body.
func (ac *AccountClient) Post(ctx context.Context, path string, body any) (*Response, error) {
	return ac.parent.doRequest(ctx, "POST", ac.accountPath(path), body)
}

// Put performs an account-scoped PUT request with a JSON body.
func (ac *AccountClient) Put(ctx context.Context, path string, body any) (*Response, error) {
	return ac.parent.doRequest(ctx, "PUT", ac.accountPath(path), body)
}

// Patch performs an account-scoped PATCH request with a JSON body.
func (ac *AccountClient) Patch(ctx context.Context, path string, body any) (*Response, error) {
	return ac.parent.doRequest(ctx, "PATCH", ac.accountPath(path), body)
}

// Delete performs an account-scoped DELETE request.
func (ac *AccountClient) Delete(ctx context.Context, path string) (*Response, error) {
	return ac.parent.doRequest(ctx, "DELETE", ac.accountPath(path), nil)
}

// GetAll fetches all pages for an account-scoped paginated resource.
func (ac *AccountClient) GetAll(ctx context.Context, path string) ([]json.RawMessage, error) {
	return ac.parent.GetAllWithLimit(ctx, ac.accountPath(path), 0)
}

// GetAllWithLimit fetches pages for an account-scoped paginated resource up to a limit.
func (ac *AccountClient) GetAllWithLimit(ctx context.Context, path string, limit int) ([]json.RawMessage, error) {
	return ac.parent.GetAllWithLimit(ctx, ac.accountPath(path), limit)
}

// accountPath prepends the account ID to the path.
// Absolute URLs are returned unchanged (e.g., pagination Link headers).
func (ac *AccountClient) accountPath(path string) string {
	if strings.HasPrefix(path, "http://") || strings.HasPrefix(path, "https://") {
		return path
	}
	if !strings.HasPrefix(path, "/") {
		path = "/" + path
	}
	prefix := "/" + ac.accountID
	if strings.HasPrefix(path, prefix) {
		rest := path[len(prefix):]
		if rest == "" || rest[0] == '/' || rest[0] == '?' {
			return path
		}
	}
	return "/" + ac.accountID + path
}

// discardHandler is a slog.Handler that discards all log records.
type discardHandler struct{}

func (discardHandler) Enabled(context.Context, slog.Level) bool  { return false }
func (discardHandler) Handle(context.Context, slog.Record) error { return nil }
func (h discardHandler) WithAttrs([]slog.Attr) slog.Handler      { return h }
func (h discardHandler) WithGroup(string) slog.Handler           { return h }

// Get performs a GET request.
func (c *Client) Get(ctx context.Context, path string) (*Response, error) {
	return c.doRequest(ctx, "GET", path, nil)
}

// Post performs a POST request with a JSON body.
func (c *Client) Post(ctx context.Context, path string, body any) (*Response, error) {
	return c.doRequest(ctx, "POST", path, body)
}

// Put performs a PUT request with a JSON body.
func (c *Client) Put(ctx context.Context, path string, body any) (*Response, error) {
	return c.doRequest(ctx, "PUT", path, body)
}

// Patch performs a PATCH request with a JSON body.
func (c *Client) Patch(ctx context.Context, path string, body any) (*Response, error) {
	return c.doRequest(ctx, "PATCH", path, body)
}

// Delete performs a DELETE request.
func (c *Client) Delete(ctx context.Context, path string) (*Response, error) {
	return c.doRequest(ctx, "DELETE", path, nil)
}

// GetAll fetches all pages for a paginated resource.
func (c *Client) GetAll(ctx context.Context, path string) ([]json.RawMessage, error) {
	return c.GetAllWithLimit(ctx, path, 0)
}

// GetAllWithLimit fetches pages for a paginated resource up to a limit.
func (c *Client) GetAllWithLimit(ctx context.Context, path string, limit int) ([]json.RawMessage, error) {
	var allResults []json.RawMessage
	baseURL, err := c.buildURL(path)
	if err != nil {
		return nil, err
	}
	url := baseURL
	var page int

	for page = 1; page <= c.httpOpts.MaxPages; page++ {
		resp, err := c.doRequestURL(ctx, "GET", url, nil)
		if err != nil {
			return nil, err
		}

		var items []json.RawMessage
		if err := json.Unmarshal(resp.Data, &items); err != nil {
			return nil, fmt.Errorf("failed to parse response: %w", err)
		}
		allResults = append(allResults, items...)

		if limit > 0 && len(allResults) >= limit {
			allResults = allResults[:limit]
			break
		}

		nextURL := parseNextLink(resp.Headers.Get("Link"))
		if nextURL == "" {
			break
		}
		nextURL = resolveURL(url, nextURL)
		if !isSameOrigin(nextURL, baseURL) {
			return nil, fmt.Errorf("pagination Link header points to different origin: %s", nextURL)
		}
		url = nextURL
	}

	if page > c.httpOpts.MaxPages {
		c.logger.Warn("pagination capped", "maxPages", c.httpOpts.MaxPages)
	}

	return allResults, nil
}

func (c *Client) doRequest(ctx context.Context, method, path string, body any) (*Response, error) {
	url, err := c.buildURL(path)
	if err != nil {
		return nil, err
	}
	return c.doRequestURL(ctx, method, url, body)
}

func (c *Client) doRequestURL(ctx context.Context, method, url string, body any) (*Response, error) {
	// POST and operations that opt out via WithNoRetry: single attempt only.
	if method == "POST" || isNoRetry(ctx) {
		resp, err := c.singleRequest(ctx, method, url, body, 1)
		if err == nil {
			return resp, nil
		}
		// Only retry if this was a 401 that triggered successful token refresh
		if apiErr, ok := err.(*Error); ok && apiErr.Retryable && apiErr.Code == CodeAuth {
			c.logger.Debug("token refreshed, retrying mutation", "method", method)
			info := RequestInfo{Method: method, URL: url, Attempt: 1}
			c.hooks.OnRetry(ctx, info, 2, err)
			return c.singleRequest(ctx, method, url, body, 2)
		}
		return nil, err
	}

	// Idempotent requests (GET, PUT, PATCH, DELETE): retry with exponential backoff
	var attempt int
	var lastErr error

	for attempt = 1; attempt <= c.httpOpts.MaxRetries; attempt++ {
		resp, err := c.singleRequest(ctx, method, url, body, attempt)
		if err == nil {
			return resp, nil
		}

		var delay time.Duration
		if re, ok := err.(*retryableError); ok {
			lastErr = re.err
			if re.retryAfter > 0 {
				delay = re.retryAfter
			} else {
				delay = c.backoffDelay(attempt)
			}
		} else if apiErr, ok := err.(*Error); ok {
			if !apiErr.Retryable {
				return nil, err
			}
			lastErr = err
			delay = c.backoffDelay(attempt)
		} else {
			return nil, err
		}

		c.logger.Debug("retrying request", "attempt", attempt, "maxRetries", c.httpOpts.MaxRetries, "delay", delay, "error", lastErr)

		info := RequestInfo{Method: method, URL: url, Attempt: attempt}
		c.hooks.OnRetry(ctx, info, attempt+1, lastErr)

		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		case <-time.After(delay):
			continue
		}
	}

	return nil, fmt.Errorf("request failed after %d retries: %w", c.httpOpts.MaxRetries, lastErr)
}

func (c *Client) singleRequest(ctx context.Context, method, url string, body any, attempt int) (*Response, error) {
	ctx = contextWithAttempt(ctx, attempt)

	var bodyReader io.Reader
	if body != nil {
		bodyBytes, err := json.Marshal(body)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal body: %w", err)
		}
		bodyReader = strings.NewReader(string(bodyBytes))
	}

	req, err := http.NewRequestWithContext(ctx, method, url, bodyReader)
	if err != nil {
		return nil, err
	}

	if err := c.authStrategy.Authenticate(ctx, req); err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", c.userAgent)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	// Add ETag for cached GET requests
	var cacheKey string
	if method == "GET" && c.cache != nil {
		cacheKey = c.cache.Key(url, "", req.Header.Get("Authorization"))
		if etag := c.cache.GetETag(cacheKey); etag != "" {
			req.Header.Set("If-None-Match", etag)
			c.logger.Debug("cache conditional request", "etag", etag)
		}
	}

	c.logger.Debug("http request", "method", method, "url", url, "attempt", attempt)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, ErrNetwork(err)
	}
	defer func() { _ = resp.Body.Close() }()

	c.logger.Debug("http response", "status", resp.StatusCode)

	requestID := resp.Header.Get("X-Request-Id")

	switch resp.StatusCode {
	case http.StatusNotModified: // 304
		if cacheKey != "" {
			c.logger.Debug("cache hit", "status", 304)
			cached := c.cache.GetBody(cacheKey)
			if cached != nil {
				return &Response{
					Data:       cached,
					StatusCode: http.StatusOK,
					Headers:    resp.Header,
					FromCache:  true,
				}, nil
			}
		}
		return nil, ErrAPI(304, "304 received but no cached response available")

	case http.StatusOK, http.StatusCreated, http.StatusNoContent:
		respBody, err := limitedReadAll(resp.Body, MaxResponseBodyBytes)
		if err != nil {
			return nil, fmt.Errorf("failed to read response: %w", err)
		}

		if resp.StatusCode == http.StatusNoContent {
			respBody = json.RawMessage("null")
		}

		// Cache GET responses with ETag
		if method == "GET" && cacheKey != "" {
			if etag := resp.Header.Get("ETag"); etag != "" {
				_ = c.cache.Set(cacheKey, respBody, etag)
				c.logger.Debug("cache stored", "etag", etag)
			}
		}

		return &Response{
			Data:       respBody,
			StatusCode: resp.StatusCode,
			Headers:    resp.Header,
		}, nil

	case http.StatusTooManyRequests: // 429
		retryAfter := parseRetryAfter(resp.Header.Get("Retry-After"))
		return nil, &retryableError{
			err: &Error{
				Code:       CodeRateLimit,
				Message:    "Rate limited",
				HTTPStatus: 429,
				Retryable:  true,
				RequestID:  requestID,
			},
			retryAfter: time.Duration(retryAfter) * time.Second,
		}

	case http.StatusUnauthorized: // 401
		return nil, &Error{Code: CodeAuth, Message: "Authentication failed", HTTPStatus: 401, RequestID: requestID}

	case http.StatusForbidden: // 403
		if method != "GET" {
			return nil, &Error{Code: CodeForbidden, Message: "Access denied: insufficient scope", Hint: "Re-authenticate with full scope", HTTPStatus: 403, RequestID: requestID}
		}
		return nil, &Error{Code: CodeForbidden, Message: "Access denied", HTTPStatus: 403, RequestID: requestID}

	case http.StatusNotFound: // 404
		return nil, &Error{Code: CodeNotFound, Message: fmt.Sprintf("Resource not found: %s", url), HTTPStatus: 404, RequestID: requestID}

	case http.StatusUnprocessableEntity: // 422
		respBody, _ := limitedReadAll(resp.Body, MaxErrorBodyBytes)
		msg := "Validation failed"
		var parsed struct {
			Error   string `json:"error"`
			Message string `json:"message"`
		}
		if json.Unmarshal(respBody, &parsed) == nil {
			if parsed.Error != "" {
				msg = truncateString(parsed.Error, MaxErrorMessageBytes)
			} else if parsed.Message != "" {
				msg = truncateString(parsed.Message, MaxErrorMessageBytes)
			}
		}
		return nil, &Error{Code: CodeValidation, Message: msg, HTTPStatus: 422, RequestID: requestID}

	case http.StatusInternalServerError: // 500
		return nil, &Error{Code: CodeAPI, Message: "Server error (500)", HTTPStatus: 500, Retryable: true, RequestID: requestID}

	case http.StatusBadGateway, http.StatusServiceUnavailable, http.StatusGatewayTimeout: // 502, 503, 504
		return nil, &Error{
			Code:       CodeAPI,
			Message:    fmt.Sprintf("Gateway error (%d)", resp.StatusCode),
			HTTPStatus: resp.StatusCode,
			Retryable:  true,
			RequestID:  requestID,
		}

	default:
		respBody, _ := limitedReadAll(resp.Body, MaxErrorBodyBytes)
		var apiErr struct {
			Error   string `json:"error"`
			Message string `json:"message"`
		}
		if json.Unmarshal(respBody, &apiErr) == nil {
			msg := apiErr.Error
			if msg == "" {
				msg = apiErr.Message
			}
			if msg != "" {
				return nil, &Error{Code: CodeAPI, Message: truncateString(msg, MaxErrorMessageBytes), HTTPStatus: resp.StatusCode, RequestID: requestID}
			}
		}
		return nil, &Error{Code: CodeAPI, Message: fmt.Sprintf("Request failed (HTTP %d)", resp.StatusCode), HTTPStatus: resp.StatusCode, RequestID: requestID}
	}
}

func (c *Client) buildURL(path string) (string, error) {
	if strings.HasPrefix(path, "https://") {
		return path, nil
	}
	if strings.HasPrefix(path, "http://") {
		return "", fmt.Errorf("URL must use HTTPS, got: %s", path)
	}
	if !strings.HasPrefix(path, "/") {
		path = "/" + path
	}
	base := strings.TrimSuffix(c.cfg.BaseURL, "/")
	return base + path, nil
}

func (c *Client) backoffDelay(attempt int) time.Duration {
	delay := c.httpOpts.BaseDelay * time.Duration(1<<(attempt-1))
	jitter := time.Duration(rand.Int63n(int64(c.httpOpts.MaxJitter))) // #nosec G404 -- jitter doesn't need cryptographic randomness
	return delay + jitter
}

// parseRetryAfter parses the Retry-After header value.
func parseRetryAfter(header string) int {
	if header == "" {
		return 0
	}
	if seconds, err := strconv.Atoi(header); err == nil && seconds > 0 {
		return seconds
	}
	if t, err := http.ParseTime(header); err == nil {
		seconds := int(time.Until(t).Seconds())
		if seconds > 0 {
			return seconds
		}
	}
	return 0
}

// Config returns a copy of the client configuration.
func (c *Client) Config() Config {
	return *c.cfg
}

// --- Account-independent services (on Client) ---

// Sessions returns the SessionsService for session operations.
func (c *Client) Sessions() *SessionsService {
	c.sessionsMu.Lock()
	defer c.sessionsMu.Unlock()
	if c.sessions == nil {
		c.sessions = NewSessionsService(c)
	}
	return c.sessions
}

// Devices returns the DevicesService for device operations.
func (c *Client) Devices() *DevicesService {
	c.devicesMu.Lock()
	defer c.devicesMu.Unlock()
	if c.devices == nil {
		c.devices = NewDevicesService(c)
	}
	return c.devices
}

// Identity returns the IdentityService for identity operations.
func (c *Client) Identity() *IdentityService {
	c.identityMu.Lock()
	defer c.identityMu.Unlock()
	if c.identity == nil {
		c.identity = NewIdentityService(c)
	}
	return c.identity
}

// --- Account-scoped services (on AccountClient) ---

// Boards returns the BoardsService for board operations.
func (ac *AccountClient) Boards() *BoardsService {
	ac.mu.Lock()
	defer ac.mu.Unlock()
	if ac.boards == nil {
		ac.boards = NewBoardsService(ac)
	}
	return ac.boards
}

// Columns returns the ColumnsService for column operations.
func (ac *AccountClient) Columns() *ColumnsService {
	ac.mu.Lock()
	defer ac.mu.Unlock()
	if ac.columns == nil {
		ac.columns = NewColumnsService(ac)
	}
	return ac.columns
}

// Cards returns the CardsService for card operations.
func (ac *AccountClient) Cards() *CardsService {
	ac.mu.Lock()
	defer ac.mu.Unlock()
	if ac.cards == nil {
		ac.cards = NewCardsService(ac)
	}
	return ac.cards
}

// Comments returns the CommentsService for comment operations.
func (ac *AccountClient) Comments() *CommentsService {
	ac.mu.Lock()
	defer ac.mu.Unlock()
	if ac.comments == nil {
		ac.comments = NewCommentsService(ac)
	}
	return ac.comments
}

// Steps returns the StepsService for step operations.
func (ac *AccountClient) Steps() *StepsService {
	ac.mu.Lock()
	defer ac.mu.Unlock()
	if ac.steps == nil {
		ac.steps = NewStepsService(ac)
	}
	return ac.steps
}

// Reactions returns the ReactionsService for reaction operations.
func (ac *AccountClient) Reactions() *ReactionsService {
	ac.mu.Lock()
	defer ac.mu.Unlock()
	if ac.reactions == nil {
		ac.reactions = NewReactionsService(ac)
	}
	return ac.reactions
}

// Notifications returns the NotificationsService for notification operations.
func (ac *AccountClient) Notifications() *NotificationsService {
	ac.mu.Lock()
	defer ac.mu.Unlock()
	if ac.notifications == nil {
		ac.notifications = NewNotificationsService(ac)
	}
	return ac.notifications
}

// Tags returns the TagsService for tag operations.
func (ac *AccountClient) Tags() *TagsService {
	ac.mu.Lock()
	defer ac.mu.Unlock()
	if ac.tags == nil {
		ac.tags = NewTagsService(ac)
	}
	return ac.tags
}

// Users returns the UsersService for user operations.
func (ac *AccountClient) Users() *UsersService {
	ac.mu.Lock()
	defer ac.mu.Unlock()
	if ac.users == nil {
		ac.users = NewUsersService(ac)
	}
	return ac.users
}

// Pins returns the PinsService for pin operations.
func (ac *AccountClient) Pins() *PinsService {
	ac.mu.Lock()
	defer ac.mu.Unlock()
	if ac.pins == nil {
		ac.pins = NewPinsService(ac)
	}
	return ac.pins
}

// Uploads returns the UploadsService for upload operations.
func (ac *AccountClient) Uploads() *UploadsService {
	ac.mu.Lock()
	defer ac.mu.Unlock()
	if ac.uploads == nil {
		ac.uploads = NewUploadsService(ac)
	}
	return ac.uploads
}

// Webhooks returns the WebhooksService for webhook operations.
func (ac *AccountClient) Webhooks() *WebhooksService {
	ac.mu.Lock()
	defer ac.mu.Unlock()
	if ac.webhooks == nil {
		ac.webhooks = NewWebhooksService(ac)
	}
	return ac.webhooks
}

// --- Service type declarations ---
// These are placeholder types for the generated service layer.
// The actual methods are generated from the OpenAPI spec.

// SessionsService handles session operations (account-independent).
type SessionsService struct{ client *Client }

// NewSessionsService creates a new SessionsService.
func NewSessionsService(client *Client) *SessionsService {
	return &SessionsService{client: client}
}

// DevicesService handles device registration operations (account-independent).
type DevicesService struct{ client *Client }

// NewDevicesService creates a new DevicesService.
func NewDevicesService(client *Client) *DevicesService {
	return &DevicesService{client: client}
}

// IdentityService handles identity operations (account-independent).
type IdentityService struct{ client *Client }

// NewIdentityService creates a new IdentityService.
func NewIdentityService(client *Client) *IdentityService {
	return &IdentityService{client: client}
}

// BoardsService handles board operations.
type BoardsService struct{ client *AccountClient }

// NewBoardsService creates a new BoardsService.
func NewBoardsService(client *AccountClient) *BoardsService {
	return &BoardsService{client: client}
}

// ColumnsService handles column operations.
type ColumnsService struct{ client *AccountClient }

// NewColumnsService creates a new ColumnsService.
func NewColumnsService(client *AccountClient) *ColumnsService {
	return &ColumnsService{client: client}
}

// CardsService handles card operations.
type CardsService struct{ client *AccountClient }

// NewCardsService creates a new CardsService.
func NewCardsService(client *AccountClient) *CardsService {
	return &CardsService{client: client}
}

// CommentsService handles comment operations.
type CommentsService struct{ client *AccountClient }

// NewCommentsService creates a new CommentsService.
func NewCommentsService(client *AccountClient) *CommentsService {
	return &CommentsService{client: client}
}

// StepsService handles step operations.
type StepsService struct{ client *AccountClient }

// NewStepsService creates a new StepsService.
func NewStepsService(client *AccountClient) *StepsService {
	return &StepsService{client: client}
}

// ReactionsService handles reaction operations.
type ReactionsService struct{ client *AccountClient }

// NewReactionsService creates a new ReactionsService.
func NewReactionsService(client *AccountClient) *ReactionsService {
	return &ReactionsService{client: client}
}

// NotificationsService handles notification operations.
type NotificationsService struct{ client *AccountClient }

// NewNotificationsService creates a new NotificationsService.
func NewNotificationsService(client *AccountClient) *NotificationsService {
	return &NotificationsService{client: client}
}

// TagsService handles tag operations.
type TagsService struct{ client *AccountClient }

// NewTagsService creates a new TagsService.
func NewTagsService(client *AccountClient) *TagsService {
	return &TagsService{client: client}
}

// UsersService handles user operations.
type UsersService struct{ client *AccountClient }

// NewUsersService creates a new UsersService.
func NewUsersService(client *AccountClient) *UsersService {
	return &UsersService{client: client}
}

// PinsService handles pin operations.
type PinsService struct{ client *AccountClient }

// NewPinsService creates a new PinsService.
func NewPinsService(client *AccountClient) *PinsService {
	return &PinsService{client: client}
}

// UploadsService handles upload operations.
type UploadsService struct{ client *AccountClient }

// NewUploadsService creates a new UploadsService.
func NewUploadsService(client *AccountClient) *UploadsService {
	return &UploadsService{client: client}
}

// WebhooksService handles webhook operations.
type WebhooksService struct{ client *AccountClient }

// NewWebhooksService creates a new WebhooksService.
func NewWebhooksService(client *AccountClient) *WebhooksService {
	return &WebhooksService{client: client}
}
