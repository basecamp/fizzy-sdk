package fizzy

import (
	"context"
	"errors"
	"net/http"
	"testing"
	"time"
)

// --- version ---

func TestVersion(t *testing.T) {
	if Version == "" {
		t.Fatal("Version must not be empty")
	}
	if APIVersion == "" {
		t.Fatal("APIVersion must not be empty")
	}
}

// --- errors ---

func TestErrorMessage(t *testing.T) {
	e := &Error{Message: "boom"}
	if e.Error() != "boom" {
		t.Fatalf("got %q", e.Error())
	}
}

func TestErrorMessageWithHint(t *testing.T) {
	e := &Error{Message: "boom", Hint: "try again"}
	if e.Error() != "boom: try again" {
		t.Fatalf("got %q", e.Error())
	}
}

func TestErrorUnwrap(t *testing.T) {
	cause := errors.New("root")
	e := &Error{Message: "wrapped", Cause: cause}
	if !errors.Is(e, cause) {
		t.Fatal("Unwrap should expose cause")
	}
}

func TestExitCodeFor(t *testing.T) {
	cases := []struct {
		code string
		want int
	}{
		{CodeUsage, ExitUsage},
		{CodeNotFound, ExitNotFound},
		{CodeAuth, ExitAuth},
		{CodeForbidden, ExitForbidden},
		{CodeRateLimit, ExitRateLimit},
		{CodeNetwork, ExitNetwork},
		{CodeAPI, ExitAPI},
		{CodeValidation, ExitValidation},
		{CodeAmbiguous, ExitAmbiguous},
		{"unknown", ExitAPI},
	}
	for _, tc := range cases {
		if got := ExitCodeFor(tc.code); got != tc.want {
			t.Errorf("ExitCodeFor(%q) = %d, want %d", tc.code, got, tc.want)
		}
	}
}

func TestErrorExitCode(t *testing.T) {
	e := ErrNotFound("Board", "123")
	if e.ExitCode() != ExitNotFound {
		t.Fatalf("got %d", e.ExitCode())
	}
}

func TestErrorConstructors(t *testing.T) {
	if e := ErrUsage("bad"); e.Code != CodeUsage || e.Message != "bad" {
		t.Fatalf("ErrUsage: %+v", e)
	}
	if e := ErrUsageHint("bad", "fix"); e.Hint != "fix" {
		t.Fatalf("ErrUsageHint: %+v", e)
	}
	if e := ErrNotFound("Board", "42"); e.Code != CodeNotFound {
		t.Fatalf("ErrNotFound: %+v", e)
	}
	if e := ErrNotFoundHint("Board", "42", "check name"); e.Hint != "check name" {
		t.Fatalf("ErrNotFoundHint: %+v", e)
	}
	if e := ErrAuth("no token"); e.Code != CodeAuth {
		t.Fatalf("ErrAuth: %+v", e)
	}
	if e := ErrForbidden("denied"); e.HTTPStatus != 403 {
		t.Fatalf("ErrForbidden: %+v", e)
	}
	if e := ErrForbiddenScope(); e.Hint == "" {
		t.Fatal("ErrForbiddenScope should have hint")
	}
	if e := ErrRateLimit(0); e.Hint != "Try again later" {
		t.Fatalf("ErrRateLimit(0): %+v", e)
	}
	if e := ErrRateLimit(30); e.Hint != "Try again in 30 seconds" {
		t.Fatalf("ErrRateLimit(30): %+v", e)
	}
	if e := ErrNetwork(errors.New("timeout")); !e.Retryable || e.Cause == nil {
		t.Fatalf("ErrNetwork: %+v", e)
	}
	if e := ErrAPI(500, "oops"); e.HTTPStatus != 500 {
		t.Fatalf("ErrAPI: %+v", e)
	}
	if e := ErrAmbiguous("board", nil); e.Hint != "Be more specific" {
		t.Fatalf("ErrAmbiguous(nil): %+v", e)
	}
	if e := ErrAmbiguous("board", []string{"a", "b"}); e.Hint == "Be more specific" {
		t.Fatalf("ErrAmbiguous with matches should list them: %+v", e)
	}
}

func TestAsError(t *testing.T) {
	orig := ErrAuth("test")
	if AsError(orig) != orig {
		t.Fatal("AsError should return the same *Error")
	}

	plain := errors.New("plain")
	wrapped := AsError(plain)
	if wrapped.Code != CodeAPI {
		t.Fatalf("AsError wraps as API: %+v", wrapped)
	}
	if wrapped.Cause != plain {
		t.Fatal("AsError should preserve cause")
	}
}

// --- config ---

func TestNormalizeBaseURL(t *testing.T) {
	if NormalizeBaseURL("https://fizzy.do/") != "https://fizzy.do" {
		t.Fatal("should strip trailing slash")
	}
	if NormalizeBaseURL("https://fizzy.do") != "https://fizzy.do" {
		t.Fatal("should leave clean URL unchanged")
	}
}

func TestDefaultConfig(t *testing.T) {
	t.Setenv("XDG_CACHE_HOME", "/tmp/test-cache")
	cfg := DefaultConfig()
	if cfg.BaseURL != "https://fizzy.do" {
		t.Fatalf("BaseURL = %q", cfg.BaseURL)
	}
	if cfg.CacheEnabled {
		t.Fatal("CacheEnabled should default false")
	}
}

func TestLoadConfigFromEnv(t *testing.T) {
	cfg := DefaultConfig()
	t.Setenv("FIZZY_API_URL", "https://custom.api")
	t.Setenv("FIZZY_ACCOUNT", "acct-1")
	t.Setenv("FIZZY_CACHE_ENABLED", "true")
	cfg.LoadConfigFromEnv()

	if cfg.BaseURL != "https://custom.api" {
		t.Fatalf("BaseURL = %q", cfg.BaseURL)
	}
	if cfg.Account != "acct-1" {
		t.Fatalf("Account = %q", cfg.Account)
	}
	if !cfg.CacheEnabled {
		t.Fatal("CacheEnabled should be true")
	}
}

func TestLoadConfigFileNotFound(t *testing.T) {
	cfg, err := LoadConfig("/nonexistent/config.json")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.BaseURL != "https://fizzy.do" {
		t.Fatal("should return defaults for missing file")
	}
}

// --- security ---

func TestRequireSecureEndpoint(t *testing.T) {
	cases := []struct {
		url     string
		wantErr bool
	}{
		{"https://fizzy.do/boards.json", false},
		{"http://localhost:3000/boards.json", false},
		{"http://127.0.0.1:3000/boards.json", false},
		{"http://[::1]:3000/boards.json", false},
		{"http://foo.localhost/boards.json", false},
		{"http://fizzy.do/boards.json", true},
	}
	for _, tc := range cases {
		err := RequireSecureEndpoint(tc.url)
		if (err != nil) != tc.wantErr {
			t.Errorf("RequireSecureEndpoint(%q) err=%v, wantErr=%v", tc.url, err, tc.wantErr)
		}
	}
}

func TestRedactHeaders(t *testing.T) {
	h := http.Header{}
	h.Set("Authorization", "Bearer secret")
	h.Set("Cookie", "session=abc")
	h.Set("Content-Type", "application/json")

	redacted := RedactHeaders(h)
	if redacted.Get("Authorization") != "[REDACTED]" {
		t.Fatal("Authorization not redacted")
	}
	if redacted.Get("Cookie") != "[REDACTED]" {
		t.Fatal("Cookie not redacted")
	}
	if redacted.Get("Content-Type") != "application/json" {
		t.Fatal("Content-Type should be unchanged")
	}
	// Original should be untouched
	if h.Get("Authorization") != "Bearer secret" {
		t.Fatal("original header mutated")
	}
}

func TestIsSameOrigin(t *testing.T) {
	if !isSameOrigin("https://fizzy.do/a", "https://fizzy.do/b") {
		t.Fatal("same origin should match")
	}
	if isSameOrigin("https://fizzy.do/a", "https://evil.com/b") {
		t.Fatal("different hosts should not match")
	}
	if !isSameOrigin("https://fizzy.do:443/a", "https://fizzy.do/b") {
		t.Fatal("default port should be normalized")
	}
}

func TestTruncateString(t *testing.T) {
	if truncateString("short", 100) != "short" {
		t.Fatal("should not truncate short strings")
	}
	result := truncateString("this is a long string", 10)
	if len(result) > 10 {
		t.Fatalf("result too long: %q", result)
	}
	if result != "this is..." {
		t.Fatalf("got %q", result)
	}
}

// --- webhooks ---

func TestWebhookSignature(t *testing.T) {
	payload := []byte("test payload")
	secret := "test-secret"

	sig := ComputeWebhookSignature(payload, secret)
	if sig == "" {
		t.Fatal("signature should not be empty")
	}
	if !VerifyWebhookSignature(payload, sig, secret) {
		t.Fatal("valid signature should verify")
	}
	if VerifyWebhookSignature(payload, "wrong", secret) {
		t.Fatal("wrong signature should not verify")
	}
	if VerifyWebhookSignature(payload, sig, "wrong-secret") {
		t.Fatal("wrong secret should not verify")
	}
	if VerifyWebhookSignature(payload, "", secret) {
		t.Fatal("empty signature should not verify")
	}
	if VerifyWebhookSignature(payload, sig, "") {
		t.Fatal("empty secret should not verify")
	}
}

// --- pagination ---

func TestParseNextLink(t *testing.T) {
	cases := []struct {
		header string
		want   string
	}{
		{`<https://fizzy.do/boards?page=2>; rel="next"`, "https://fizzy.do/boards?page=2"},
		{`<https://fizzy.do/boards?page=2>; rel="next", <https://fizzy.do/boards?page=5>; rel="last"`, "https://fizzy.do/boards?page=2"},
		{`<https://fizzy.do/boards?page=1>; rel="prev"`, ""},
		{"", ""},
	}
	for _, tc := range cases {
		if got := parseNextLink(tc.header); got != tc.want {
			t.Errorf("parseNextLink(%q) = %q, want %q", tc.header, got, tc.want)
		}
	}
}

// --- cache ---

func TestCacheKey(t *testing.T) {
	c := NewCache(t.TempDir())
	k1 := c.Key("https://fizzy.do/boards.json", "acct", "token1")
	k2 := c.Key("https://fizzy.do/boards.json", "acct", "token2")
	k3 := c.Key("https://fizzy.do/boards.json", "acct", "token1")

	if k1 == k2 {
		t.Fatal("different tokens should produce different keys")
	}
	if k1 != k3 {
		t.Fatal("same inputs should produce same key")
	}
	if len(k1) != 64 {
		t.Fatalf("key should be 64-char hex, got %d chars", len(k1))
	}
}

func TestCacheSetAndGet(t *testing.T) {
	dir := t.TempDir()
	c := NewCache(dir)

	if err := c.Set("k1", []byte("body1"), "etag1"); err != nil {
		t.Fatalf("Set: %v", err)
	}
	if c.GetETag("k1") != "etag1" {
		t.Fatal("GetETag mismatch")
	}
	if string(c.GetBody("k1")) != "body1" {
		t.Fatal("GetBody mismatch")
	}
}

func TestCacheInvalidate(t *testing.T) {
	dir := t.TempDir()
	c := NewCache(dir)

	_ = c.Set("k1", []byte("body1"), "etag1")
	_ = c.Invalidate("k1")

	if c.GetETag("k1") != "" {
		t.Fatal("etag should be gone after invalidate")
	}
	if c.GetBody("k1") != nil {
		t.Fatal("body should be gone after invalidate")
	}
}

func TestCacheClear(t *testing.T) {
	dir := t.TempDir()
	c := NewCache(dir)

	_ = c.Set("k1", []byte("body1"), "etag1")
	_ = c.Set("k2", []byte("body2"), "etag2")
	_ = c.Clear()

	if c.GetETag("k1") != "" || c.GetETag("k2") != "" {
		t.Fatal("etags should be gone after clear")
	}
}

// --- circuit breaker ---

func TestCircuitBreakerDefaults(t *testing.T) {
	cfg := DefaultCircuitBreakerConfig()
	if cfg.FailureThreshold != 5 {
		t.Fatalf("FailureThreshold = %d", cfg.FailureThreshold)
	}
	if cfg.SuccessThreshold != 2 {
		t.Fatalf("SuccessThreshold = %d", cfg.SuccessThreshold)
	}
	if cfg.OpenTimeout != 30*time.Second {
		t.Fatalf("OpenTimeout = %v", cfg.OpenTimeout)
	}
}

func TestCircuitBreakerStartsClosed(t *testing.T) {
	cb := newCircuitBreaker(nil)
	if cb.State() != "closed" {
		t.Fatalf("initial state = %q", cb.State())
	}
	if !cb.Allow() {
		t.Fatal("closed circuit should allow requests")
	}
}

func TestCircuitBreakerOpensAfterFailures(t *testing.T) {
	cb := newCircuitBreaker(&CircuitBreakerConfig{FailureThreshold: 3})
	for i := 0; i < 3; i++ {
		cb.RecordFailure()
	}
	if cb.State() != "open" {
		t.Fatalf("state = %q, want open", cb.State())
	}
	if cb.Allow() {
		t.Fatal("open circuit should reject requests")
	}
}

func TestCircuitBreakerHalfOpenAfterTimeout(t *testing.T) {
	now := time.Now()
	cb := newCircuitBreaker(&CircuitBreakerConfig{
		FailureThreshold: 1,
		OpenTimeout:      time.Second,
		Now:              func() time.Time { return now },
	})
	cb.RecordFailure()
	if cb.State() != "open" {
		t.Fatalf("state = %q, want open", cb.State())
	}

	// Advance past timeout
	now = now.Add(2 * time.Second)
	if !cb.Allow() {
		t.Fatal("should allow after timeout (half-open)")
	}
	if cb.State() != "half-open" {
		t.Fatalf("state = %q, want half-open", cb.State())
	}
}

func TestCircuitBreakerClosesAfterSuccesses(t *testing.T) {
	now := time.Now()
	cb := newCircuitBreaker(&CircuitBreakerConfig{
		FailureThreshold: 1,
		SuccessThreshold: 2,
		OpenTimeout:      time.Second,
		Now:              func() time.Time { return now },
	})
	cb.RecordFailure()
	now = now.Add(2 * time.Second)
	cb.Allow() // transitions to half-open

	cb.RecordSuccess()
	cb.RecordSuccess()
	if cb.State() != "closed" {
		t.Fatalf("state = %q, want closed", cb.State())
	}
}

func TestCircuitBreakerReopensOnHalfOpenFailure(t *testing.T) {
	now := time.Now()
	cb := newCircuitBreaker(&CircuitBreakerConfig{
		FailureThreshold: 1,
		OpenTimeout:      time.Second,
		Now:              func() time.Time { return now },
	})
	cb.RecordFailure()
	now = now.Add(2 * time.Second)
	cb.Allow() // half-open

	cb.RecordFailure()
	if cb.State() != "open" {
		t.Fatalf("state = %q, want open", cb.State())
	}
}

func TestCircuitBreakerRegistry(t *testing.T) {
	reg := newCircuitBreakerRegistry(nil)
	a := reg.get("scope-a")
	b := reg.get("scope-b")
	a2 := reg.get("scope-a")

	if a == b {
		t.Fatal("different scopes should get different breakers")
	}
	if a != a2 {
		t.Fatal("same scope should get same breaker")
	}
}

// --- bulkhead ---

func TestBulkheadDefaults(t *testing.T) {
	cfg := DefaultBulkheadConfig()
	if cfg.MaxConcurrent != 10 {
		t.Fatalf("MaxConcurrent = %d", cfg.MaxConcurrent)
	}
}

func TestBulkheadTryAcquire(t *testing.T) {
	bh := newBulkhead(&BulkheadConfig{MaxConcurrent: 2})

	rel1, ok1 := bh.TryAcquire()
	rel2, ok2 := bh.TryAcquire()
	_, ok3 := bh.TryAcquire()

	if !ok1 || !ok2 {
		t.Fatal("first two acquires should succeed")
	}
	if ok3 {
		t.Fatal("third acquire should fail (full)")
	}
	if bh.Available() != 0 {
		t.Fatalf("Available = %d, want 0", bh.Available())
	}
	if bh.InUse() != 2 {
		t.Fatalf("InUse = %d, want 2", bh.InUse())
	}

	rel1()
	if bh.Available() != 1 {
		t.Fatalf("Available = %d after release, want 1", bh.Available())
	}
	rel2()
}

func TestBulkheadAcquireNoWait(t *testing.T) {
	bh := newBulkhead(&BulkheadConfig{MaxConcurrent: 1, MaxWait: 0})
	rel, err := bh.Acquire(context.Background())
	if err != nil {
		t.Fatalf("Acquire: %v", err)
	}
	defer rel()

	_, err = bh.Acquire(context.Background())
	if !errors.Is(err, ErrBulkheadFull) {
		t.Fatalf("err = %v, want ErrBulkheadFull", err)
	}
}

func TestBulkheadAcquireCancelledContext(t *testing.T) {
	bh := newBulkhead(&BulkheadConfig{MaxConcurrent: 1, MaxWait: time.Second})
	rel, _ := bh.Acquire(context.Background())
	defer rel()

	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	_, err := bh.Acquire(ctx)
	if err == nil {
		t.Fatal("should fail with cancelled context")
	}
}

func TestBulkheadRegistry(t *testing.T) {
	reg := newBulkheadRegistry(nil)
	a := reg.get("scope-a")
	b := reg.get("scope-b")
	a2 := reg.get("scope-a")

	if a == b {
		t.Fatal("different scopes should get different bulkheads")
	}
	if a != a2 {
		t.Fatal("same scope should get same bulkhead")
	}
}

// --- rate limiter ---

func TestRateLimiterDefaults(t *testing.T) {
	cfg := DefaultRateLimitConfig()
	if cfg.RequestsPerSecond != 50 {
		t.Fatalf("RequestsPerSecond = %f", cfg.RequestsPerSecond)
	}
	if cfg.BurstSize != 10 {
		t.Fatalf("BurstSize = %d", cfg.BurstSize)
	}
}

func TestRateLimiterTokenBucket(t *testing.T) {
	now := time.Now()
	rl := newRateLimiter(&RateLimitConfig{
		RequestsPerSecond: 10,
		BurstSize:         3,
		Now:               func() time.Time { return now },
	})

	// Should have 3 tokens (burst size)
	for i := 0; i < 3; i++ {
		if !rl.Allow() {
			t.Fatalf("Allow() should succeed for token %d", i)
		}
	}
	if rl.Allow() {
		t.Fatal("Allow() should fail when tokens exhausted")
	}

	// Advance 1 second: 10 tokens refilled, capped at burst size (3)
	now = now.Add(time.Second)
	if !rl.Allow() {
		t.Fatal("Allow() should succeed after refill")
	}
}

func TestRateLimiterRetryAfter(t *testing.T) {
	now := time.Now()
	rl := newRateLimiter(&RateLimitConfig{
		RequestsPerSecond: 100,
		BurstSize:         10,
		RespectRetryAfter: true,
		Now:               func() time.Time { return now },
	})

	rl.SetRetryAfter(now.Add(5 * time.Second))
	if rl.Allow() {
		t.Fatal("should block during retry-after")
	}
	if rl.RetryAfterRemaining() == 0 {
		t.Fatal("RetryAfterRemaining should be > 0")
	}

	now = now.Add(6 * time.Second)
	if !rl.Allow() {
		t.Fatal("should allow after retry-after expires")
	}
}

func TestRateLimiterRetryAfterDisabled(t *testing.T) {
	now := time.Now()
	rl := newRateLimiter(&RateLimitConfig{
		RequestsPerSecond: 100,
		BurstSize:         10,
		RespectRetryAfter: false,
		Now:               func() time.Time { return now },
	})

	rl.SetRetryAfter(now.Add(5 * time.Second))
	if !rl.Allow() {
		t.Fatal("should allow when RespectRetryAfter is false")
	}
}

func TestRateLimiterReserve(t *testing.T) {
	now := time.Now()
	rl := newRateLimiter(&RateLimitConfig{
		RequestsPerSecond: 10,
		BurstSize:         2,
		Now:               func() time.Time { return now },
	})

	if d := rl.Reserve(); d != 0 {
		t.Fatalf("Reserve() = %v, want 0 (tokens available)", d)
	}
	if d := rl.Reserve(); d != 0 {
		t.Fatalf("Reserve() = %v, want 0 (last token)", d)
	}
	// Third reserve: tokens exhausted, should return small positive duration
	d := rl.Reserve()
	if d <= 0 || d > time.Second {
		t.Fatalf("Reserve() = %v, want small positive duration", d)
	}
}

func TestRateLimiterTokens(t *testing.T) {
	now := time.Now()
	rl := newRateLimiter(&RateLimitConfig{
		RequestsPerSecond: 10,
		BurstSize:         5,
		Now:               func() time.Time { return now },
	})

	if rl.Tokens() != 5 {
		t.Fatalf("Tokens() = %f, want 5", rl.Tokens())
	}
	rl.Allow()
	if rl.Tokens() != 4 {
		t.Fatalf("Tokens() = %f after Allow(), want 4", rl.Tokens())
	}
}
