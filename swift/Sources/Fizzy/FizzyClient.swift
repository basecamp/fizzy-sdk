import Foundation

/// The main entry point for the Fizzy SDK.
///
/// Creates an HTTP client configured with authentication, retry,
/// caching, and hooks. Provides direct access to API services.
///
/// ```swift
/// let client = FizzyClient(
///     accessToken: "your-token",
///     userAgent: "my-app/1.0 (you@example.com)"
/// )
///
/// let identity = try await client.identity.me()
/// let boards = try await client.boards.list(accountId: "abc123")
/// ```
public final class FizzyClient: Sendable {
    /// The client configuration.
    public let config: FizzyConfig

    /// The hooks for observability.
    public let hooks: any FizzyHooks

    /// The internal HTTP client used by all services.
    package let httpClient: HTTPClient

    /// Creates a client with a static access token.
    ///
    /// - Parameters:
    ///   - accessToken: Bearer access token string.
    ///   - userAgent: Required User-Agent identifying your app (e.g., "MyApp/1.0 (you@example.com)").
    ///   - config: Configuration options (defaults are sensible for most uses).
    ///   - hooks: Optional observability hooks.
    public convenience init(
        accessToken: String,
        userAgent: String,
        config: FizzyConfig = FizzyConfig(),
        hooks: (any FizzyHooks)? = nil
    ) {
        self.init(
            tokenProvider: StaticTokenProvider(accessToken),
            userAgent: userAgent,
            config: config,
            hooks: hooks
        )
    }

    /// Creates a client with a custom token provider.
    ///
    /// Use this initializer for token refresh scenarios.
    ///
    /// - Parameters:
    ///   - tokenProvider: A provider that returns access tokens.
    ///   - userAgent: Required User-Agent identifying your app.
    ///   - config: Configuration options.
    ///   - hooks: Optional observability hooks.
    ///   - transport: Optional custom transport (for testing).
    public convenience init(
        tokenProvider: any TokenProvider,
        userAgent: String,
        config: FizzyConfig = FizzyConfig(),
        hooks: (any FizzyHooks)? = nil,
        transport: (any Transport)? = nil
    ) {
        self.init(
            auth: BearerAuth(tokenProvider: tokenProvider),
            userAgent: userAgent,
            config: config,
            hooks: hooks,
            transport: transport
        )
    }

    /// Creates a client with a custom authentication strategy.
    ///
    /// Use this initializer for non-Bearer authentication schemes
    /// such as cookie-based auth or custom API keys.
    ///
    /// - Parameters:
    ///   - auth: An authentication strategy applied to every request.
    ///   - userAgent: Required User-Agent identifying your app.
    ///   - config: Configuration options.
    ///   - hooks: Optional observability hooks.
    ///   - transport: Optional custom transport (for testing).
    public init(
        auth: any AuthStrategy,
        userAgent: String,
        config: FizzyConfig = FizzyConfig(),
        hooks: (any FizzyHooks)? = nil,
        transport: (any Transport)? = nil
    ) {
        let effectiveConfig = FizzyConfig(
            baseURL: config.baseURL,
            userAgent: userAgent,
            enableRetry: config.enableRetry,
            enableCache: config.enableCache,
            maxPages: config.maxPages,
            timeoutInterval: config.timeoutInterval,
            allowInsecure: config.allowInsecure
        )
        let effectiveHooks = hooks ?? NoopHooks()
        let effectiveTransport = transport ?? URLSessionTransport()
        let cache = config.enableCache ? ETagCache() : nil

        // Validate base URL uses HTTPS (skip for localhost/loopback or explicit opt-out)
        if let url = URL(string: effectiveConfig.baseURL) {
            do {
                try HTTPClient.requireSecureTransport(url, allowInsecure: effectiveConfig.allowInsecure)
            } catch {
                preconditionFailure("Base URL must use HTTPS: \(effectiveConfig.baseURL)")
            }
        }

        self.config = effectiveConfig
        self.hooks = effectiveHooks
        self.httpClient = HTTPClient(
            transport: effectiveTransport,
            authStrategy: auth,
            config: effectiveConfig,
            hooks: effectiveHooks,
            cache: cache
        )
    }

    // MARK: - Service Cache

    private let lock = NSLock()
    // Nonisolated(unsafe) because access is serialized by NSLock
    nonisolated(unsafe) private var serviceCache: [String: Any] = [:]

    /// Returns a cached service instance, creating it with the factory if needed.
    ///
    /// This method is the extension point for adding services from external packages.
    /// Services are created lazily on first access and cached for the lifetime of
    /// this `FizzyClient`.
    ///
    /// - Parameters:
    ///   - key: Unique string key for the service (typically the property name).
    ///   - factory: Closure that creates the service instance.
    /// - Returns: The cached or newly created service instance.
    public func service<T>(_ key: String, factory: () -> T) -> T {
        lock.withLock {
            if let existing = serviceCache[key] as? T {
                return existing
            }
            let instance = factory()
            serviceCache[key] = instance
            return instance
        }
    }
}
