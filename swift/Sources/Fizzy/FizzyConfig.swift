import Foundation

/// Configuration for a Fizzy SDK client.
///
/// Provides sensible defaults matching the other SDK implementations.
/// All properties are immutable after construction.
public struct FizzyConfig: Sendable {
    /// Base URL for the Fizzy API.
    public let baseURL: String

    /// User-Agent header value sent with every request.
    public let userAgent: String

    /// Whether to automatically retry on 429/503 responses.
    public let enableRetry: Bool

    /// Whether to enable ETag-based HTTP caching.
    public let enableCache: Bool

    /// Maximum number of pages to follow during pagination (safety cap).
    public let maxPages: Int

    /// Request timeout interval in seconds.
    public let timeoutInterval: TimeInterval

    /// Allow HTTP (non-TLS) connections. Required for self-hosted instances
    /// accessed over private networks (e.g., Tailscale). Default: `false`.
    public let allowInsecure: Bool

    /// SDK version string.
    public static let sdkVersion = "0.1.3"

    /// Fizzy API version this SDK targets.
    public static let apiVersion = "2026-03-01"

    /// Default User-Agent header value.
    public static let defaultUserAgent = "fizzy-sdk-swift/\(sdkVersion) (api:\(apiVersion))"

    /// Default base URL for the Fizzy API.
    public static let defaultBaseURL = "https://fizzy.do"

    /// Creates a new configuration with the given options.
    ///
    /// - Parameters:
    ///   - baseURL: API base URL (default: `https://fizzy.do`)
    ///   - userAgent: User-Agent header (default: `fizzy-sdk-swift/VERSION (api:API_VERSION)`)
    ///   - enableRetry: Enable automatic retry on 429/503 (default: `true`)
    ///   - enableCache: Enable ETag-based caching (default: `false`)
    ///   - maxPages: Maximum pages to follow (default: `10_000`)
    ///   - timeoutInterval: Request timeout in seconds (default: `30`)
    ///   - allowInsecure: Allow HTTP connections for self-hosted instances (default: `false`)
    public init(
        baseURL: String = defaultBaseURL,
        userAgent: String = defaultUserAgent,
        enableRetry: Bool = true,
        enableCache: Bool = false,
        maxPages: Int = 10_000,
        timeoutInterval: TimeInterval = 30,
        allowInsecure: Bool = false
    ) {
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        self.userAgent = userAgent
        self.enableRetry = enableRetry
        self.enableCache = enableCache
        self.maxPages = maxPages
        self.timeoutInterval = timeoutInterval
        self.allowInsecure = allowInsecure
    }
}
