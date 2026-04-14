import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Cookie-based authentication strategy for session-based auth.
///
/// Sets the `Cookie` header with `session_token=<value>` for each request.
/// Used for mobile and web session authentication in Fizzy.
///
/// ```swift
/// let client = FizzyClient(
///     auth: CookieAuth(sessionToken: "your-session-token"),
///     userAgent: "my-app/1.0"
/// )
/// ```
public struct CookieAuth: AuthStrategy {
    private let tokenProvider: any TokenProvider

    /// Creates a CookieAuth strategy with a static session token.
    ///
    /// - Parameter sessionToken: The session token value.
    public init(sessionToken: String) {
        self.tokenProvider = StaticTokenProvider(sessionToken)
    }

    /// Creates a CookieAuth strategy with a custom token provider.
    ///
    /// Use this for dynamic session token scenarios (e.g., rotation).
    ///
    /// - Parameter tokenProvider: A provider that returns session tokens.
    public init(tokenProvider: any TokenProvider) {
        self.tokenProvider = tokenProvider
    }

    public func authenticate(_ request: inout URLRequest) async throws {
        let token = try await tokenProvider.accessToken()
        request.setValue("session_token=\(token)", forHTTPHeaderField: "Cookie")
    }
}
