import Foundation

/// A client bound to a specific Fizzy account (kept for structural parity with other SDKs).
///
/// Fizzy services are accessed directly from `FizzyClient`, but `AccountClient`
/// exists as the service-hosting layer with the lazy cache pattern, allowing
/// the generator to emit the same `AccountClient+Services.swift` extension.
///
/// ```swift
/// let client = FizzyClient(accessToken: "token", userAgent: "app/1.0")
/// // Services are accessed via the client directly:
/// let boards = try await client.boards.list(accountId: "abc123")
/// ```
public final class AccountClient: Sendable {
    /// The parent client.
    public let client: FizzyClient

    /// Base URL for requests.
    public var baseURL: String {
        client.config.baseURL
    }

    /// The internal HTTP client (for use by services).
    package var httpClient: HTTPClient { client.httpClient }

    /// The hooks instance (for use by services).
    package var hooks: any FizzyHooks { client.hooks }

    /// Maximum pages for pagination (for use by services).
    package var maxPages: Int { client.config.maxPages }

    // MARK: - Service Cache

    private let lock = NSLock()
    // Nonisolated(unsafe) because access is serialized by NSLock
    nonisolated(unsafe) private var serviceCache: [String: Any] = [:]

    package init(client: FizzyClient) {
        self.client = client
    }

    /// Returns a cached service instance, creating it with the factory if needed.
    ///
    /// This method is the extension point for adding services from external packages.
    /// Services are created lazily on first access and cached for the lifetime of
    /// this `AccountClient`.
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
