import { describe, it, expect, beforeAll, afterAll, afterEach } from "vitest";
import { setupServer } from "msw/node";
import { http, HttpResponse } from "msw";
import {
  createFizzyClient,
  FizzyError,
  Errors,
  errorFromResponse,
  isFizzyError,
  isErrorCode,
  parseNextLink,
  resolveURL,
  isSameOrigin,
  redactHeaders,
  redactHeadersRecord,
  ListResult,
  VERSION,
  API_VERSION,
} from "../src/index.js";
import { isLocalhost } from "../src/security.js";
import { normalizeUrlPath } from "../src/client.js";
import { verifyWebhookSignature, signWebhookPayload } from "../src/webhooks/verify.js";

// =============================================================================
// FizzyError
// =============================================================================

describe("FizzyError", () => {
  it("constructs with code and message", () => {
    const err = new FizzyError("not_found", "Board 42 not found");
    expect(err.code).toBe("not_found");
    expect(err.message).toBe("Board 42 not found");
    expect(err.name).toBe("FizzyError");
    expect(err.retryable).toBe(false);
    expect(err.httpStatus).toBeUndefined();
    expect(err.hint).toBeUndefined();
    expect(err.retryAfter).toBeUndefined();
    expect(err.requestId).toBeUndefined();
  });

  it("constructs with all options", () => {
    const cause = new Error("underlying");
    const err = new FizzyError("rate_limit", "Too many requests", {
      hint: "Slow down",
      httpStatus: 429,
      retryable: true,
      retryAfter: 60,
      requestId: "req-123",
      cause,
    });
    expect(err.hint).toBe("Slow down");
    expect(err.httpStatus).toBe(429);
    expect(err.retryable).toBe(true);
    expect(err.retryAfter).toBe(60);
    expect(err.requestId).toBe("req-123");
    expect(err.cause).toBe(cause);
  });

  it("exitCode maps error codes", () => {
    expect(new FizzyError("usage", "bad").exitCode).toBe(1);
    expect(new FizzyError("not_found", "gone").exitCode).toBe(2);
    expect(new FizzyError("auth_required", "no").exitCode).toBe(3);
    expect(new FizzyError("forbidden", "no").exitCode).toBe(4);
    expect(new FizzyError("rate_limit", "slow").exitCode).toBe(5);
    expect(new FizzyError("network", "down").exitCode).toBe(6);
    expect(new FizzyError("api_error", "500").exitCode).toBe(7);
    expect(new FizzyError("ambiguous", "?").exitCode).toBe(8);
    expect(new FizzyError("validation", "bad").exitCode).toBe(9);
  });

  it("toJSON includes all fields", () => {
    const err = new FizzyError("api_error", "Server error", {
      httpStatus: 500,
      retryable: true,
      requestId: "req-456",
      hint: "Try again",
      retryAfter: 5,
    });
    const json = err.toJSON();
    expect(json).toEqual({
      name: "FizzyError",
      code: "api_error",
      message: "Server error",
      hint: "Try again",
      httpStatus: 500,
      retryable: true,
      retryAfter: 5,
      requestId: "req-456",
    });
  });

  it("instanceof Error", () => {
    const err = new FizzyError("network", "oops");
    expect(err).toBeInstanceOf(Error);
    expect(err).toBeInstanceOf(FizzyError);
  });
});

// =============================================================================
// Errors factory
// =============================================================================

describe("Errors factory", () => {
  it("auth()", () => {
    const err = Errors.auth();
    expect(err.code).toBe("auth_required");
    expect(err.httpStatus).toBe(401);
    expect(err.hint).toContain("access token");
  });

  it("auth() with custom hint and cause", () => {
    const cause = new Error("expired");
    const err = Errors.auth("Token expired", cause);
    expect(err.hint).toBe("Token expired");
    expect(err.cause).toBe(cause);
  });

  it("forbidden()", () => {
    const err = Errors.forbidden();
    expect(err.code).toBe("forbidden");
    expect(err.httpStatus).toBe(403);
  });

  it("notFound() without id", () => {
    const err = Errors.notFound("Board");
    expect(err.code).toBe("not_found");
    expect(err.message).toBe("Board not found");
    expect(err.httpStatus).toBe(404);
  });

  it("notFound() with id", () => {
    const err = Errors.notFound("Board", 42);
    expect(err.message).toBe("Board 42 not found");
  });

  it("rateLimit()", () => {
    const err = Errors.rateLimit(30);
    expect(err.code).toBe("rate_limit");
    expect(err.retryable).toBe(true);
    expect(err.httpStatus).toBe(429);
    expect(err.retryAfter).toBe(30);
    expect(err.hint).toContain("30");
  });

  it("rateLimit() without retryAfter", () => {
    const err = Errors.rateLimit();
    expect(err.hint).toContain("slow down");
  });

  it("validation()", () => {
    const err = Errors.validation("Name is required", "Provide a name");
    expect(err.code).toBe("validation");
    expect(err.message).toBe("Name is required");
    expect(err.hint).toBe("Provide a name");
    expect(err.httpStatus).toBe(400);
  });

  it("ambiguous() with matches", () => {
    const err = Errors.ambiguous("board", ["Board A", "Board B"]);
    expect(err.code).toBe("ambiguous");
    expect(err.hint).toContain("Board A");
    expect(err.hint).toContain("Board B");
  });

  it("ambiguous() with too many matches", () => {
    const err = Errors.ambiguous("board", Array(10).fill("x"));
    expect(err.hint).toBe("Be more specific");
  });

  it("network()", () => {
    const cause = new Error("ECONNREFUSED");
    const err = Errors.network("Connection refused", cause);
    expect(err.code).toBe("network");
    expect(err.retryable).toBe(true);
    expect(err.cause).toBe(cause);
  });

  it("apiError()", () => {
    const err = Errors.apiError("Internal error", 500, {
      retryable: true,
      requestId: "req-789",
    });
    expect(err.code).toBe("api_error");
    expect(err.httpStatus).toBe(500);
    expect(err.retryable).toBe(true);
    expect(err.requestId).toBe("req-789");
  });
});

// =============================================================================
// Type guards
// =============================================================================

describe("isFizzyError", () => {
  it("returns true for FizzyError instances", () => {
    expect(isFizzyError(new FizzyError("network", "fail"))).toBe(true);
  });

  it("returns false for plain errors", () => {
    expect(isFizzyError(new Error("not fizzy"))).toBe(false);
  });

  it("returns false for non-errors", () => {
    expect(isFizzyError("string")).toBe(false);
    expect(isFizzyError(null)).toBe(false);
    expect(isFizzyError(undefined)).toBe(false);
    expect(isFizzyError(42)).toBe(false);
  });
});

describe("isErrorCode", () => {
  it("matches specific error code", () => {
    const err = new FizzyError("not_found", "gone");
    expect(isErrorCode(err, "not_found")).toBe(true);
    expect(isErrorCode(err, "auth_required")).toBe(false);
  });

  it("returns false for non-FizzyError", () => {
    expect(isErrorCode(new Error("nope"), "not_found")).toBe(false);
  });
});

// =============================================================================
// errorFromResponse
// =============================================================================

describe("errorFromResponse", () => {
  it("maps 401 to auth_required", async () => {
    const response = new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
    const err = await errorFromResponse(response);
    expect(err.code).toBe("auth_required");
    expect(err.httpStatus).toBe(401);
    expect(err.message).toBe("Unauthorized");
  });

  it("maps 403 to forbidden", async () => {
    const response = new Response(JSON.stringify({ error: "Forbidden" }), {
      status: 403,
    });
    const err = await errorFromResponse(response);
    expect(err.code).toBe("forbidden");
  });

  it("maps 404 to not_found", async () => {
    const response = new Response(JSON.stringify({ error: "Not found" }), {
      status: 404,
    });
    const err = await errorFromResponse(response);
    expect(err.code).toBe("not_found");
  });

  it("maps 429 to rate_limit with retryAfter", async () => {
    const response = new Response(JSON.stringify({ error: "Rate limited" }), {
      status: 429,
      headers: { "Retry-After": "30" },
    });
    const err = await errorFromResponse(response);
    expect(err.code).toBe("rate_limit");
    expect(err.retryable).toBe(true);
    expect(err.retryAfter).toBe(30);
  });

  it("maps 400 to validation", async () => {
    const response = new Response(JSON.stringify({ error: "Bad request" }), {
      status: 400,
    });
    const err = await errorFromResponse(response);
    expect(err.code).toBe("validation");
  });

  it("maps 422 to validation", async () => {
    const response = new Response(
      JSON.stringify({ error: "Name can't be blank" }),
      { status: 422 },
    );
    const err = await errorFromResponse(response);
    expect(err.code).toBe("validation");
    expect(err.message).toBe("Name can't be blank");
  });

  it("maps 500 to api_error as retryable", async () => {
    const response = new Response(
      JSON.stringify({ error: "Internal error" }),
      { status: 500 },
    );
    const err = await errorFromResponse(response);
    expect(err.code).toBe("api_error");
    expect(err.retryable).toBe(true);
  });

  it("maps 502 to api_error as retryable", async () => {
    const response = new Response(null, { status: 502 });
    const err = await errorFromResponse(response);
    expect(err.code).toBe("api_error");
    expect(err.retryable).toBe(true);
  });

  it("passes requestId through", async () => {
    const response = new Response(JSON.stringify({ error: "fail" }), {
      status: 500,
    });
    const err = await errorFromResponse(response, "req-999");
    expect(err.requestId).toBe("req-999");
  });

  it("extracts error_description as hint", async () => {
    const response = new Response(
      JSON.stringify({
        error: "Validation failed",
        error_description: "Name must be present",
      }),
      { status: 422 },
    );
    const err = await errorFromResponse(response);
    expect(err.hint).toBe("Name must be present");
  });

  it("handles non-JSON body", async () => {
    const response = new Response("Gateway Timeout", { status: 504 });
    const err = await errorFromResponse(response);
    expect(err.code).toBe("api_error");
    expect(err.retryable).toBe(true);
  });

  it("handles empty body", async () => {
    const response = new Response(null, {
      status: 401,
      statusText: "Unauthorized",
    });
    const err = await errorFromResponse(response);
    expect(err.code).toBe("auth_required");
  });
});

// =============================================================================
// Config validation
// =============================================================================

describe("createFizzyClient config validation", () => {
  it("rejects HTTP for non-localhost", () => {
    expect(() =>
      createFizzyClient({
        accessToken: "token",
        baseUrl: "http://evil.example.com",
      }),
    ).toThrow(FizzyError);

    try {
      createFizzyClient({
        accessToken: "token",
        baseUrl: "http://evil.example.com",
      });
    } catch (err) {
      expect((err as FizzyError).code).toBe("usage");
    }
  });

  it("allows HTTP for localhost", () => {
    const client = createFizzyClient({
      accessToken: "token",
      baseUrl: "http://localhost:3000",
    });
    expect(client).toBeDefined();
  });

  it("allows HTTP for 127.0.0.1", () => {
    const client = createFizzyClient({
      accessToken: "token",
      baseUrl: "http://127.0.0.1:3000",
    });
    expect(client).toBeDefined();
  });

  it("allows HTTPS for any host", () => {
    const client = createFizzyClient({
      accessToken: "token",
      baseUrl: "https://fizzy.do",
    });
    expect(client).toBeDefined();
  });

  it("rejects both auth and accessToken", () => {
    expect(() =>
      createFizzyClient({
        accessToken: "token",
        auth: { authenticate: async () => {} },
        baseUrl: "https://fizzy.do",
      }),
    ).toThrow(FizzyError);

    try {
      createFizzyClient({
        accessToken: "token",
        auth: { authenticate: async () => {} },
        baseUrl: "https://fizzy.do",
      });
    } catch (err) {
      expect((err as FizzyError).code).toBe("usage");
      expect((err as FizzyError).message).toContain("not both");
    }
  });

  it("rejects missing auth", () => {
    expect(() =>
      createFizzyClient({ baseUrl: "https://fizzy.do" }),
    ).toThrow(FizzyError);

    try {
      createFizzyClient({ baseUrl: "https://fizzy.do" });
    } catch (err) {
      expect((err as FizzyError).code).toBe("usage");
    }
  });

  it("exports VERSION and API_VERSION", () => {
    expect(VERSION).toMatch(/^\d+\.\d+\.\d+$/);
    expect(API_VERSION).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });
});

// =============================================================================
// Pagination utilities
// =============================================================================

describe("parseNextLink", () => {
  it("extracts next URL from Link header", () => {
    const link = '<https://fizzy.do/999/boards.json?page=2>; rel="next"';
    expect(parseNextLink(link)).toBe(
      "https://fizzy.do/999/boards.json?page=2",
    );
  });

  it("extracts next from multi-value Link", () => {
    const link =
      '<https://fizzy.do/boards.json?page=1>; rel="prev", <https://fizzy.do/boards.json?page=3>; rel="next"';
    expect(parseNextLink(link)).toBe(
      "https://fizzy.do/boards.json?page=3",
    );
  });

  it("returns null when no next rel", () => {
    const link = '<https://fizzy.do/boards.json?page=1>; rel="prev"';
    expect(parseNextLink(link)).toBeNull();
  });

  it("returns null for null header", () => {
    expect(parseNextLink(null)).toBeNull();
  });

  it("returns null for empty string", () => {
    expect(parseNextLink("")).toBeNull();
  });

  it("handles relative URLs", () => {
    const link = '</boards.json?page=2>; rel="next"';
    expect(parseNextLink(link)).toBe("/boards.json?page=2");
  });
});

describe("resolveURL", () => {
  it("resolves relative URL against base", () => {
    const result = resolveURL(
      "https://fizzy.do/999/boards.json",
      "/999/boards.json?page=2",
    );
    expect(result).toBe("https://fizzy.do/999/boards.json?page=2");
  });

  it("returns absolute URL unchanged", () => {
    const result = resolveURL(
      "https://fizzy.do/boards.json",
      "https://other.com/boards.json?page=2",
    );
    expect(result).toBe("https://other.com/boards.json?page=2");
  });

  it("handles invalid URLs gracefully", () => {
    const result = resolveURL("not-a-url", "also-not-a-url");
    expect(result).toBe("also-not-a-url");
  });
});

describe("isSameOrigin", () => {
  it("same origin returns true", () => {
    expect(
      isSameOrigin("https://fizzy.do/a", "https://fizzy.do/b"),
    ).toBe(true);
  });

  it("same origin with port returns true", () => {
    expect(
      isSameOrigin(
        "http://localhost:3000/a",
        "http://localhost:3000/b",
      ),
    ).toBe(true);
  });

  it("different host returns false", () => {
    expect(
      isSameOrigin("https://fizzy.do/a", "https://evil.com/a"),
    ).toBe(false);
  });

  it("different scheme returns false", () => {
    expect(
      isSameOrigin("https://fizzy.do/a", "http://fizzy.do/a"),
    ).toBe(false);
  });

  it("different port returns false", () => {
    expect(
      isSameOrigin(
        "http://localhost:3000/a",
        "http://localhost:4000/a",
      ),
    ).toBe(false);
  });

  it("invalid URLs return false", () => {
    expect(isSameOrigin("not-a-url", "also-not")).toBe(false);
  });
});

// =============================================================================
// ListResult
// =============================================================================

describe("ListResult", () => {
  it("extends Array", () => {
    const result = new ListResult([1, 2, 3], { truncated: false });
    expect(result).toBeInstanceOf(Array);
    expect(Array.isArray(result)).toBe(true);
    expect(result.length).toBe(3);
    expect(result[0]).toBe(1);
    expect(result[2]).toBe(3);
  });

  it("provides meta", () => {
    const result = new ListResult(["a", "b"], { truncated: true });
    expect(result.meta.truncated).toBe(true);
  });

  it("supports Array methods", () => {
    const result = new ListResult([1, 2, 3], { truncated: false });
    const mapped = result.map((x) => x * 2);
    expect(mapped).toEqual([2, 4, 6]);
    expect(mapped).toBeInstanceOf(Array);
  });

  it("supports spread", () => {
    const result = new ListResult(["a", "b"], { truncated: false });
    const spread = [...result];
    expect(spread).toEqual(["a", "b"]);
  });

  it("handles empty array", () => {
    const result = new ListResult([], { truncated: false });
    expect(result.length).toBe(0);
    expect(result.meta.truncated).toBe(false);
  });
});

// =============================================================================
// Security utilities
// =============================================================================

describe("redactHeaders", () => {
  it("redacts sensitive headers", () => {
    const headers = new Headers({
      Authorization: "Bearer secret-token",
      Cookie: "session=abc123",
      "Content-Type": "application/json",
      "X-Custom": "visible",
    });
    const redacted = redactHeaders(headers);
    expect(redacted["authorization"]).toBe("[REDACTED]");
    expect(redacted["cookie"]).toBe("[REDACTED]");
    expect(redacted["content-type"]).toBe("application/json");
    expect(redacted["x-custom"]).toBe("visible");
  });
});

describe("redactHeadersRecord", () => {
  it("redacts sensitive headers in record", () => {
    const headers = {
      Authorization: "Bearer secret",
      "Set-Cookie": "session=xyz",
      "X-CSRF-Token": "csrf-value",
      Accept: "application/json",
    };
    const redacted = redactHeadersRecord(headers);
    expect(redacted["Authorization"]).toBe("[REDACTED]");
    expect(redacted["Set-Cookie"]).toBe("[REDACTED]");
    expect(redacted["X-CSRF-Token"]).toBe("[REDACTED]");
    expect(redacted["Accept"]).toBe("application/json");
  });
});

describe("isLocalhost", () => {
  it("matches localhost", () => {
    expect(isLocalhost("localhost")).toBe(true);
    expect(isLocalhost("LOCALHOST")).toBe(true);
  });

  it("matches 127.0.0.1", () => {
    expect(isLocalhost("127.0.0.1")).toBe(true);
  });

  it("matches ::1", () => {
    expect(isLocalhost("::1")).toBe(true);
  });

  it("matches *.localhost", () => {
    expect(isLocalhost("app.localhost")).toBe(true);
    expect(isLocalhost("dev.test.localhost")).toBe(true);
  });

  it("rejects non-localhost", () => {
    expect(isLocalhost("example.com")).toBe(false);
    expect(isLocalhost("localhost.evil.com")).toBe(false);
  });
});

// =============================================================================
// normalizeUrlPath
// =============================================================================

describe("normalizeUrlPath", () => {
  it("normalizes board paths", () => {
    expect(normalizeUrlPath("http://localhost/999/boards/42.json")).toBe(
      "/{accountId}/boards/{boardId}.json",
    );
  });

  it("normalizes card paths", () => {
    expect(normalizeUrlPath("http://localhost/999/cards/123")).toBe(
      "/{accountId}/cards/{cardNumber}",
    );
  });

  it("normalizes nested paths", () => {
    expect(
      normalizeUrlPath(
        "http://localhost/999/cards/123/comments/456/reactions.json",
      ),
    ).toBe("/{accountId}/cards/{cardNumber}/comments/{commentId}/reactions.json");
  });

  it("handles paths without .json suffix", () => {
    expect(normalizeUrlPath("http://localhost/999/boards/42")).toBe(
      "/{accountId}/boards/{boardId}",
    );
  });

  it("handles list paths", () => {
    expect(normalizeUrlPath("http://localhost/999/boards.json")).toBe(
      "/{accountId}/boards.json",
    );
  });
});

// =============================================================================
// Webhook signature verification
// =============================================================================

describe("webhook signature", () => {
  const secret = "test-secret-key";
  const payload = '{"event":"card.created","card_id":42}';

  it("signWebhookPayload produces hex HMAC-SHA256", () => {
    const sig = signWebhookPayload(payload, secret);
    expect(sig).toMatch(/^[0-9a-f]{64}$/);
  });

  it("verifyWebhookSignature accepts valid signature", () => {
    const sig = signWebhookPayload(payload, secret);
    expect(verifyWebhookSignature(payload, sig, secret)).toBe(true);
  });

  it("verifyWebhookSignature rejects wrong signature", () => {
    expect(verifyWebhookSignature(payload, "wrong", secret)).toBe(false);
  });

  it("verifyWebhookSignature rejects wrong payload", () => {
    const sig = signWebhookPayload(payload, secret);
    expect(verifyWebhookSignature("tampered", sig, secret)).toBe(false);
  });

  it("verifyWebhookSignature rejects empty secret", () => {
    expect(verifyWebhookSignature(payload, "sig", "")).toBe(false);
  });

  it("verifyWebhookSignature rejects empty signature", () => {
    expect(verifyWebhookSignature(payload, "", secret)).toBe(false);
  });

  it("handles Buffer payload", () => {
    const buf = Buffer.from(payload);
    const sig = signWebhookPayload(buf, secret);
    expect(verifyWebhookSignature(buf, sig, secret)).toBe(true);
  });
});

// =============================================================================
// Client integration (MSW-backed)
// =============================================================================

const server = setupServer();
beforeAll(() => server.listen({ onUnhandledRequest: "bypass" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe("client integration", () => {
  const BASE_URL = "http://localhost:9877";

  it("sends Authorization header", async () => {
    let capturedAuth: string | null = null;
    server.use(
      http.get(`${BASE_URL}/999/boards.json`, ({ request }) => {
        capturedAuth = request.headers.get("Authorization");
        return HttpResponse.json([]);
      }),
    );

    const client = createFizzyClient({
      accessToken: "my-secret-token",
      baseUrl: `${BASE_URL}/999`,
      enableRetry: false,
    });
    await (client as any).boards.list();
    expect(capturedAuth).toBe("Bearer my-secret-token");
  });

  it("sends User-Agent header", async () => {
    let capturedUA: string | null = null;
    server.use(
      http.get(`${BASE_URL}/999/boards.json`, ({ request }) => {
        capturedUA = request.headers.get("User-Agent");
        return HttpResponse.json([]);
      }),
    );

    const client = createFizzyClient({
      accessToken: "token",
      baseUrl: `${BASE_URL}/999`,
      enableRetry: false,
    });
    await (client as any).boards.list();
    expect(capturedUA).toContain("fizzy-sdk-ts/");
  });

  it("handles 404 as not_found error", async () => {
    server.use(
      http.get(`${BASE_URL}/999/boards/*`, () => {
        return HttpResponse.json({ error: "Not found" }, { status: 404 });
      }),
    );

    const client = createFizzyClient({
      accessToken: "token",
      baseUrl: `${BASE_URL}/999`,
      enableRetry: false,
    });

    try {
      await (client as any).boards.get(999);
      expect.unreachable("Should have thrown");
    } catch (err) {
      expect(err).toBeInstanceOf(FizzyError);
      expect((err as FizzyError).code).toBe("not_found");
      expect((err as FizzyError).httpStatus).toBe(404);
    }
  });

  it("handles 201 created", async () => {
    server.use(
      http.post(`${BASE_URL}/999/boards.json`, () => {
        return HttpResponse.json(
          {
            id: 1,
            name: "New Board",
            all_access: true,
            created_at: "2026-01-01T00:00:00Z",
            url: "https://fizzy.do/999/boards/1",
          },
          { status: 201 },
        );
      }),
    );

    const client = createFizzyClient({
      accessToken: "token",
      baseUrl: `${BASE_URL}/999`,
      enableRetry: false,
    });
    const board = await (client as any).boards.create({ name: "New Board" });
    expect(board.name).toBe("New Board");
    expect(board.id).toBe(1);
  });

  it("handles 204 no content on delete", async () => {
    server.use(
      http.delete(`${BASE_URL}/999/boards/*`, () => {
        return new HttpResponse(null, { status: 204 });
      }),
    );

    const client = createFizzyClient({
      accessToken: "token",
      baseUrl: `${BASE_URL}/999`,
      enableRetry: false,
    });
    const result = await (client as any).boards.delete(1);
    expect(result).toBeUndefined();
  });

  it("auto-paginates list operations", async () => {
    let requestCount = 0;
    server.use(
      http.get(`${BASE_URL}/999/boards.json`, ({ request }) => {
        requestCount++;
        const url = new URL(request.url);
        const page = url.searchParams.get("page");
        if (!page || page === "1") {
          return HttpResponse.json(
            [{ id: 1, name: "Board 1", all_access: true, created_at: "2026-01-01T00:00:00Z", url: `${BASE_URL}/999/boards/1` }],
            {
              headers: {
                Link: `<${BASE_URL}/999/boards.json?page=2>; rel="next"`,
              },
            },
          );
        }
        return HttpResponse.json([
          { id: 2, name: "Board 2", all_access: false, created_at: "2026-01-02T00:00:00Z", url: `${BASE_URL}/999/boards/2` },
        ]);
      }),
    );

    const client = createFizzyClient({
      accessToken: "token",
      baseUrl: `${BASE_URL}/999`,
      enableRetry: false,
    });
    const boards = await (client as any).boards.list();
    expect(boards.length).toBe(2);
    expect(boards[0].name).toBe("Board 1");
    expect(boards[1].name).toBe("Board 2");
  });

  it("forAccount creates scoped client", () => {
    const client = createFizzyClient({
      accessToken: "token",
      baseUrl: "https://fizzy.do",
    });
    const scoped = client.forAccount("123");
    expect(scoped).toBeDefined();
    expect(scoped.forAccount).toBeDefined();
  });

  it("supports async token provider", async () => {
    let capturedAuth: string | null = null;
    server.use(
      http.get(`${BASE_URL}/999/boards.json`, ({ request }) => {
        capturedAuth = request.headers.get("Authorization");
        return HttpResponse.json([]);
      }),
    );

    const client = createFizzyClient({
      accessToken: async () => "dynamic-token",
      baseUrl: `${BASE_URL}/999`,
      enableRetry: false,
    });
    await (client as any).boards.list();
    expect(capturedAuth).toBe("Bearer dynamic-token");
  });
});
