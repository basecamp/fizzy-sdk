import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import CoreFoundation

/// Internal HTTP client that wraps a `Transport` with authentication,
/// retry with exponential backoff, ETag caching, and hooks lifecycle.
///
/// This is the workhorse of the SDK. It handles the full request lifecycle:
/// 1. Token injection (auth strategy + User-Agent)
/// 2. Hooks notifications (request start/end)
/// 3. ETag cache check/store
/// 4. Retry with exponential backoff + jitter on 429/503
package final class HTTPClient: Sendable {
    private let transport: any Transport
    private let authStrategy: any AuthStrategy
    private let config: FizzyConfig
    private let hooks: any FizzyHooks
    private let cache: ETagCache?

    private static let maxJitterMs: UInt64 = 100
    private static let defaultBaseDelayMs: UInt64 = 1_000

    package init(
        transport: any Transport,
        authStrategy: any AuthStrategy,
        config: FizzyConfig,
        hooks: any FizzyHooks,
        cache: ETagCache?
    ) {
        self.transport = transport
        self.authStrategy = authStrategy
        self.config = config
        self.hooks = hooks
        self.cache = cache
    }

    /// Performs an HTTP request with full lifecycle (auth, retry, cache, hooks).
    ///
    /// - Parameters:
    ///   - method: HTTP method.
    ///   - url: Full URL string.
    ///   - body: Optional request body data.
    ///   - retryConfig: Optional per-operation retry configuration.
    /// - Returns: A tuple of (data, HTTPURLResponse).
    package func performRequest(
        method: String,
        url: String,
        body: Data? = nil,
        contentType: String? = nil,
        retryConfig: RetryConfig? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        let effectiveConfig = retryConfig ?? .default

        guard let requestURL = URL(string: url) else {
            throw FizzyError.usage(message: "Invalid URL: \(url)", hint: nil)
        }

        try Self.requireSecureTransport(requestURL, allowInsecure: config.allowInsecure)

        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        request.timeoutInterval = config.timeoutInterval

        // Set auth and standard headers
        try await authStrategy.authenticate(&request)
        request.setValue(config.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if body != nil {
            request.setValue(contentType ?? "application/json", forHTTPHeaderField: "Content-Type")
        }
        request.httpBody = body

        // ETag cache: add If-None-Match for GET requests
        if method == "GET", let cache, let etag = cache.etag(for: url) {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        // Retry loop
        let maxAttempts = max(config.enableRetry ? effectiveConfig.maxAttempts : 1, 1)

        for attempt in 1...maxAttempts {
            let info = RequestInfo(method: method, url: url, attempt: attempt)

            // Notify hooks
            safeInvokeHooks { $0.onRequestStart(info) }

            let startTime = CFAbsoluteTimeGetCurrent()

            do {
                let (data, response) = try await transport.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw FizzyError.network(message: "Invalid response type", cause: nil)
                }

                let durationMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)

                // Handle 304 Not Modified -- return cached data with a synthetic 200 response
                if httpResponse.statusCode == 304, let cache, let cached = cache.data(for: url) {
                    safeInvokeHooks {
                        $0.onRequestEnd(info, result: RequestResult(
                            statusCode: 200, durationMs: durationMs, fromCache: true))
                    }
                    let syntheticResponse = HTTPURLResponse(
                        url: httpResponse.url ?? requestURL,
                        statusCode: 200,
                        httpVersion: "HTTP/1.1",
                        headerFields: httpResponse.allHeaderFields as? [String: String] ?? [:]
                    )!
                    return (cached, syntheticResponse)
                }

                // Cache successful GET responses with ETag
                if method == "GET", httpResponse.statusCode == 200,
                   let cache, let etag = httpResponse.value(forHTTPHeaderField: "ETag") {
                    cache.store(url: url, data: data, etag: etag)
                }

                safeInvokeHooks {
                    $0.onRequestEnd(info, result: RequestResult(
                        statusCode: httpResponse.statusCode, durationMs: durationMs))
                }

                // Check if we should retry
                let statusCode = httpResponse.statusCode
                if effectiveConfig.retryOn.contains(statusCode), attempt < maxAttempts {
                    let delaySeconds = calculateDelay(
                        attempt: attempt,
                        baseDelayMs: effectiveConfig.baseDelayMs,
                        backoff: effectiveConfig.backoff,
                        retryAfterHeader: httpResponse.value(forHTTPHeaderField: "Retry-After"),
                        statusCode: statusCode
                    )
                    let error = FizzyError.fromHTTPResponse(
                        status: statusCode, data: data,
                        headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
                        requestId: httpResponse.value(forHTTPHeaderField: "X-Request-Id")
                    )
                    safeInvokeHooks { $0.onRetry(info, attempt: attempt, error: error, delaySeconds: delaySeconds) }

                    try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))

                    // Re-authenticate for retry (e.g. refresh expired token)
                    try await authStrategy.authenticate(&request)
                    continue
                }

                return (data, httpResponse)

            } catch let error as FizzyError {
                // The transport's own verdict, rethrown — with a .network's
                // cause projected like a raw failure (SPEC §9), since a
                // transport wrapping URLSession chains its URLError.
                throw Self.projectedTransportError(error)
            } catch {
                // Network-level error. Projected once, before anything
                // renders it (SPEC §9): the retry hook and the cause chain see
                // the same URL-free shape.
                let error = Self.projectedTransportError(error)
                let durationMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
                safeInvokeHooks {
                    $0.onRequestEnd(info, result: RequestResult(statusCode: 0, durationMs: durationMs))
                }

                if attempt < maxAttempts {
                    let delaySeconds = calculateDelay(
                        attempt: attempt,
                        baseDelayMs: effectiveConfig.baseDelayMs,
                        backoff: effectiveConfig.backoff,
                        retryAfterHeader: nil,
                        statusCode: nil
                    )
                    safeInvokeHooks {
                        $0.onRetry(info, attempt: attempt, error: error, delaySeconds: delaySeconds)
                    }
                    try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                    continue
                }

                throw FizzyError.network(message: "Network error", cause: error)
            }
        }

        // Should not reach here, but just in case
        throw FizzyError.network(message: "Request failed after \(maxAttempts) attempts", cause: nil)
    }

    /// Fetches a pagination follow-up page using the same auth context.
    package func fetchPage(url: String) async throws -> (Data, HTTPURLResponse) {
        guard let requestURL = URL(string: url) else {
            throw FizzyError.usage(message: "Invalid pagination URL: \(url)", hint: nil)
        }

        try Self.requireSecureTransport(requestURL, allowInsecure: config.allowInsecure)

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.timeoutInterval = config.timeoutInterval

        try await authStrategy.authenticate(&request)
        request.setValue(config.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await transport.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FizzyError.network(message: "Invalid response type", cause: nil)
        }

        return (data, httpResponse)
    }

    // MARK: - Transport error projection (SPEC §9)

    /// How far ``projectedTransportError(_:depth:)`` follows a `.network`
    /// cause chain. Any real chain is one or two links deep; the bound keeps a
    /// caller-built cycle from spinning.
    private static let maxCauseChainDepth = 8

    /// Projection of a transport failure before it becomes the SDK's error or
    /// reaches a hook. `URLError` carries the failing URL in its `userInfo` —
    /// `NSURLErrorFailingURLErrorKey`, its string twin, and the session task's
    /// own description — and Swift's default rendering of
    /// `.network(message:cause:)` prints all of it, query included, which on a
    /// signed URL is the credential. The error is rebuilt from parts this SDK
    /// chooses: the same code, so a caller's `URLError` matching classifies it
    /// as before, and the failing URL as origin and
    /// path — never its query, userinfo or fragment. A transport that already
    /// speaks `.network` keeps its message and has its cause projected the same
    /// way. Any other error is the transport's own diagnostic and passes
    /// through unchanged.
    static func projectedTransportError(_ error: any Error, depth: Int = 0) -> any Error {
        if let urlError = error as? URLError {
            // Nothing the transport wrote survives — not even its description,
            // which a custom Transport can build around the URL; the code is
            // the diagnostic, and Foundation describes it on its own.
            var userInfo: [String: Any] = [:]
            let failingURL = urlError.failingURL?.absoluteString
                ?? urlError.userInfo[NSURLErrorFailingURLStringErrorKey] as? String
            if let failingURL, let projected = URL(string: stripQueryAndFragment(failingURL)) {
                userInfo[NSURLErrorFailingURLErrorKey] = projected
                userInfo[NSURLErrorFailingURLStringErrorKey] = projected.absoluteString
            }
            return URLError(urlError.code, userInfo: userInfo)
        }
        if let fizzyError = error as? FizzyError, case .network(let message, let cause) = fizzyError {
            guard let cause, depth < maxCauseChainDepth else { return FizzyError.network(message: message, cause: nil) }
            return FizzyError.network(message: message, cause: projectedTransportError(cause, depth: depth + 1))
        }
        return error
    }

    /// Renders a URL as origin and path only — no userinfo, no query (where a
    /// signed credential rides), no fragment. Rebuilt from a parse; a URL with
    /// no complete origin renders as the fixed token, never as any of its own
    /// text.
    private static func stripQueryAndFragment(_ url: String) -> String {
        guard let components = URLComponents(string: url),
              let scheme = components.scheme,
              let host = components.host, !host.isEmpty
        else { return "unparsable" }
        let renderedHost = host.contains(":") && !host.hasPrefix("[") ? "[\(host)]" : host
        let port = components.port.map { ":\($0)" } ?? ""
        return "\(scheme)://\(renderedHost)\(port)\(components.percentEncodedPath)"
    }

    // MARK: - Private

    private func calculateDelay(
        attempt: Int,
        baseDelayMs: UInt64,
        backoff: RetryBackoff,
        retryAfterHeader: String?,
        statusCode: Int?
    ) -> TimeInterval {
        // For 429, respect Retry-After header
        if statusCode == 429, let retryAfter = FizzyError.parseRetryAfter(retryAfterHeader) {
            return TimeInterval(retryAfter)
        }

        let base: UInt64
        switch backoff {
        case .exponential:
            base = baseDelayMs * (1 << UInt64(attempt - 1))
        case .linear:
            base = baseDelayMs * UInt64(attempt)
        case .constant:
            base = baseDelayMs
        }

        // Add jitter (0-100ms)
        let jitter = UInt64.random(in: 0...Self.maxJitterMs)
        return TimeInterval(base + jitter) / 1000.0
    }

    private func safeInvokeHooks(_ invoke: (any FizzyHooks) -> Void) {
        invoke(hooks)
    }

    /// Ensures the URL uses HTTPS (or localhost for development).
    ///
    /// - Parameters:
    ///   - url: The URL to validate.
    ///   - allowInsecure: When `true`, skip enforcement (for self-hosted instances).
    static func requireSecureTransport(_ url: URL, allowInsecure: Bool = false) throws {
        if allowInsecure { return }
        let scheme = url.scheme?.lowercased()
        if scheme == "https" { return }
        if scheme == "http", let host = url.host?.lowercased(),
           host == "localhost" || host == "127.0.0.1" || host == "::1" { return }
        throw FizzyError.usage(
            message: "Fizzy SDK requires HTTPS. Got: \(url.scheme ?? "nil")://\(url.host ?? "")",
            hint: "Use https:// for the base URL. HTTP is only allowed for localhost."
        )
    }
}

// MARK: - Retry Configuration

/// Per-operation retry configuration, sourced from behavior-model.json.
public struct RetryConfig: Sendable {
    /// Maximum number of attempts (including the initial request).
    public let maxAttempts: Int
    /// Base delay in milliseconds between retries.
    public let baseDelayMs: UInt64
    /// Backoff strategy.
    public let backoff: RetryBackoff
    /// HTTP status codes that trigger a retry.
    public let retryOn: Set<Int>

    public init(maxAttempts: Int, baseDelayMs: UInt64, backoff: RetryBackoff, retryOn: Set<Int>) {
        self.maxAttempts = maxAttempts
        self.baseDelayMs = baseDelayMs
        self.backoff = backoff
        self.retryOn = retryOn
    }

    /// Default retry configuration: 3 attempts, exponential backoff, retry on 429/503.
    public static let `default` = RetryConfig(
        maxAttempts: 3,
        baseDelayMs: 1_000,
        backoff: .exponential,
        retryOn: [429, 503]
    )
}

/// Backoff strategy for retries.
public enum RetryBackoff: String, Sendable {
    case exponential
    case linear
    case constant
}
