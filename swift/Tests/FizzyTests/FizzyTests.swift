import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import Fizzy

@Suite("FizzyConfig Tests")
struct FizzyConfigTests {
    @Test("Default config values")
    func defaultConfig() {
        let config = FizzyConfig()
        #expect(config.baseURL == "https://fizzy.do")
        #expect(config.enableRetry == true)
        #expect(config.enableCache == false)
        #expect(config.maxPages == 10_000)
        #expect(config.timeoutInterval == 30)
    }

    @Test("SDK version")
    func sdkVersion() {
        #expect(FizzyConfig.sdkVersion == "0.1.3")
        #expect(FizzyConfig.apiVersion == "2026-03-01")
    }

    @Test("Base URL strips trailing slash")
    func trailingSlash() {
        let config = FizzyConfig(baseURL: "https://fizzy.do/")
        #expect(config.baseURL == "https://fizzy.do")
    }
}

@Suite("FizzyError Tests")
struct FizzyErrorTests {
    @Test("Error from HTTP 401")
    func authError() {
        let error = FizzyError.fromHTTPResponse(
            status: 401, data: nil, headers: [:], requestId: "req-123"
        )
        #expect(error.httpStatusCode == 401)
        #expect(error.exitCode == 3)
        #expect(error.isRetryable == false)
        #expect(error.requestId == "req-123")
    }

    @Test("Error from HTTP 404")
    func notFoundError() {
        let error = FizzyError.fromHTTPResponse(
            status: 404, data: nil, headers: [:], requestId: nil
        )
        #expect(error.httpStatusCode == 404)
        #expect(error.exitCode == 2)
    }

    @Test("Error from HTTP 429 with Retry-After")
    func rateLimitError() {
        let error = FizzyError.fromHTTPResponse(
            status: 429, data: nil, headers: ["Retry-After": "30"], requestId: nil
        )
        #expect(error.httpStatusCode == 429)
        #expect(error.isRetryable == true)
        #expect(error.exitCode == 5)
        if case .rateLimit(_, let retryAfter, _, _) = error {
            #expect(retryAfter == 30)
        }
    }

    @Test("Error from HTTP 422")
    func validationError() {
        let error = FizzyError.fromHTTPResponse(
            status: 422, data: nil, headers: [:], requestId: nil
        )
        #expect(error.httpStatusCode == 422)
        #expect(error.exitCode == 9)
    }

    @Test("Error from HTTP 500")
    func serverError() {
        let error = FizzyError.fromHTTPResponse(
            status: 500, data: nil, headers: [:], requestId: nil
        )
        #expect(error.httpStatusCode == 500)
        #expect(error.isRetryable == true)
    }

    @Test("Network error is retryable")
    func networkError() {
        let error = FizzyError.network(message: "timeout", cause: nil)
        #expect(error.isRetryable == true)
        #expect(error.exitCode == 6)
    }

    @Test("Parse Retry-After seconds")
    func parseRetryAfterSeconds() {
        #expect(FizzyError.parseRetryAfter("30") == 30)
        #expect(FizzyError.parseRetryAfter("0") == nil)
        #expect(FizzyError.parseRetryAfter(nil) == nil)
        #expect(FizzyError.parseRetryAfter("") == nil)
    }
}

@Suite("Pagination Tests")
struct PaginationTests {
    @Test("Parse next link")
    func parseNextLinkHeader() {
        let header = "<https://fizzy.do/boards?page=2>; rel=\"next\", <https://fizzy.do/boards?page=5>; rel=\"last\""
        let next = parseNextLink(header)
        #expect(next == "https://fizzy.do/boards?page=2")
    }

    @Test("Parse next link nil for empty")
    func parseNextLinkEmpty() {
        #expect(parseNextLink(nil) == nil)
        #expect(parseNextLink("") == nil)
    }

    @Test("Same origin check")
    func sameOriginCheck() {
        #expect(isSameOrigin("https://fizzy.do/a", "https://fizzy.do/b") == true)
        #expect(isSameOrigin("https://fizzy.do/a", "https://evil.com/b") == false)
        #expect(isSameOrigin("https://fizzy.do:443/a", "https://fizzy.do/b") == true)
    }

    @Test("ListResult as collection")
    func listResultCollection() {
        let result = ListResult([1, 2, 3], meta: ListMeta(truncated: false))
        #expect(result.count == 3)
        #expect(result[0] == 1)
        #expect(result.meta.truncated == false)
    }
}

@Suite("JSONValue Tests")
struct JSONValueTests {
    @Test("Decode various JSON types")
    func decodeJSON() throws {
        let json = """
        {"name": "test", "count": 42, "active": true, "items": [1, 2], "meta": null}
        """
        let value = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))
        if case .object(let dict) = value {
            #expect(dict["name"] == .string("test"))
            #expect(dict["count"] == .number(42))
            #expect(dict["active"] == .bool(true))
            #expect(dict["meta"] == .null)
        } else {
            Issue.record("Expected object")
        }
    }
}

@Suite("CookieAuth Tests")
struct CookieAuthTests {
    @Test("Sets Cookie header")
    func setsCookieHeader() async throws {
        let auth = CookieAuth(sessionToken: "abc123")
        var request = URLRequest(url: URL(string: "https://fizzy.do/boards.json")!)
        try await auth.authenticate(&request)
        #expect(request.value(forHTTPHeaderField: "Cookie") == "session_token=abc123")
    }
}

@Suite("WebhookVerifier Tests")
struct WebhookVerifierTests {
    @Test("Verify valid signature")
    func validSignature() {
        let payload = "test payload"
        let secret = "test-secret"
        let signature = WebhookVerifier.computeSignature(payload: Data(payload.utf8), secret: secret)
        let valid = WebhookVerifier.verify(payload: payload, signature: signature, secret: secret)
        #expect(valid == true)
    }

    @Test("Reject invalid signature")
    func invalidSignature() {
        let valid = WebhookVerifier.verify(payload: "test", signature: "invalid", secret: "secret")
        #expect(valid == false)
    }

    @Test("Reject wrong length signature")
    func wrongLengthSignature() {
        let valid = WebhookVerifier.verify(payload: "test", signature: "abc", secret: "secret")
        #expect(valid == false)
    }
}

@Suite("ETagCache Tests")
struct ETagCacheTests {
    @Test("Store and retrieve")
    func storeAndRetrieve() {
        let cache = ETagCache(maxEntries: 10)
        cache.store(url: "https://fizzy.do/boards.json", data: Data("test".utf8), etag: "abc")
        #expect(cache.etag(for: "https://fizzy.do/boards.json") == "abc")
        #expect(cache.data(for: "https://fizzy.do/boards.json") == Data("test".utf8))
    }

    @Test("FIFO eviction")
    func fifoEviction() {
        let cache = ETagCache(maxEntries: 2)
        cache.store(url: "a", data: Data("1".utf8), etag: "e1")
        cache.store(url: "b", data: Data("2".utf8), etag: "e2")
        cache.store(url: "c", data: Data("3".utf8), etag: "e3")
        #expect(cache.etag(for: "a") == nil)
        #expect(cache.etag(for: "b") == "e2")
        #expect(cache.etag(for: "c") == "e3")
    }
}

@Suite("CircuitBreaker Tests")
struct CircuitBreakerTests {
    @Test("Opens after threshold failures")
    func opensAfterFailures() {
        let cb = CircuitBreaker(config: CircuitBreakerConfig(failureThreshold: 2, resetTimeout: 60))
        #expect(cb.allowRequest() == true)
        cb.recordFailure()
        #expect(cb.allowRequest() == true)
        cb.recordFailure()
        #expect(cb.allowRequest() == false)
    }

    @Test("Resets to closed")
    func resetsToClose() {
        let cb = CircuitBreaker(config: CircuitBreakerConfig(failureThreshold: 1))
        cb.recordFailure()
        #expect(cb.allowRequest() == false)
        cb.reset()
        #expect(cb.allowRequest() == true)
    }
}

@Suite("Bulkhead Tests")
struct BulkheadTests {
    @Test("Limits concurrency")
    func limitsConcurrency() {
        let bh = Bulkhead(config: BulkheadConfig(maxConcurrent: 2))
        #expect(bh.tryAcquire() == true)
        #expect(bh.tryAcquire() == true)
        #expect(bh.tryAcquire() == false)
        bh.release()
        #expect(bh.tryAcquire() == true)
    }
}

@Suite("RateLimiter Tests")
struct RateLimiterTests {
    @Test("Allows within limit")
    func allowsWithinLimit() {
        let rl = RateLimiter(config: RateLimiterConfig(maxRequests: 2, windowSeconds: 60))
        #expect(rl.tryAcquire() == true)
        #expect(rl.tryAcquire() == true)
        #expect(rl.tryAcquire() == false)
        #expect(rl.remaining == 0)
    }
}

@Suite("BearerAuth Tests")
struct BearerAuthTests {
    @Test("Sets Authorization header")
    func setsAuthHeader() async throws {
        let auth = BearerAuth(tokenProvider: StaticTokenProvider("tok123"))
        var request = URLRequest(url: URL(string: "https://fizzy.do/boards.json")!)
        try await auth.authenticate(&request)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer tok123")
    }
}

@Suite("HTTPS Enforcement Tests")
struct HTTPSEnforcementTests {
    @Test("HTTPS URLs are allowed")
    func httpsAllowed() throws {
        try HTTPClient.requireSecureTransport(URL(string: "https://fizzy.do/boards.json")!)
    }

    @Test("HTTP localhost is allowed")
    func httpLocalhostAllowed() throws {
        try HTTPClient.requireSecureTransport(URL(string: "http://localhost:3000/boards.json")!)
    }

    @Test("HTTP 127.0.0.1 is allowed")
    func httpLoopbackAllowed() throws {
        try HTTPClient.requireSecureTransport(URL(string: "http://127.0.0.1:3000/boards.json")!)
    }

    @Test("HTTP ::1 is allowed")
    func httpIPv6LoopbackAllowed() throws {
        try HTTPClient.requireSecureTransport(URL(string: "http://[::1]:3000/boards.json")!)
    }

    @Test("HTTP non-localhost is rejected")
    func httpNonLocalhostRejected() {
        #expect(throws: FizzyError.self) {
            try HTTPClient.requireSecureTransport(URL(string: "http://fizzy.do/boards.json")!)
        }
    }
}

@Suite("FizzyClient Service Bridge Tests")
struct FizzyClientServiceBridgeTests {
    @Test("Service accessors are reachable from FizzyClient")
    func serviceAccessors() {
        let client = FizzyClient(
            auth: BearerAuth(tokenProvider: StaticTokenProvider("test")),
            userAgent: "test/1.0 (test@example.com)"
        )
        // Typed bindings prove the bridge compiles and returns correct types.
        // If FizzyClient+Services.swift is missing or wrong, this won't compile.
        let _: BoardsService = client.boards
        let _: CardsService = client.cards
        let _: ColumnsService = client.columns
        let _: CommentsService = client.comments
        let _: DevicesService = client.devices
        let _: IdentityService = client.identity
        let _: NotificationsService = client.notifications
        let _: PinsService = client.pins
        let _: ReactionsService = client.reactions
        let _: SessionsService = client.sessions
        let _: StepsService = client.steps
        let _: TagsService = client.tags
        let _: UploadsService = client.uploads
        let _: UsersService = client.users
        let _: WebhooksService = client.webhooks
    }

    @Test("Service accessors are cached")
    func servicesCached() {
        let client = FizzyClient(
            auth: BearerAuth(tokenProvider: StaticTokenProvider("test")),
            userAgent: "test/1.0 (test@example.com)"
        )
        let boards1 = client.boards
        let boards2 = client.boards
        #expect(boards1 === boards2)
    }
}
