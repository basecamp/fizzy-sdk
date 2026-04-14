import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Orchestrates passwordless login via magic link.
///
/// The flow:
/// 1. Call `start(email:)` to create a session -- the server sends a magic link email.
/// 2. The user clicks the link, which contains a token.
/// 3. Call `redeem(token:)` with the magic link token to get a session token.
///
/// ```swift
/// let flow = MagicLinkFlow(userAgent: "my-app/1.0")
///
/// // Step 1: Request magic link
/// let pendingToken = try await flow.start(email: "user@example.com")
///
/// // Step 2: User clicks the magic link (out of band)
///
/// // Step 3: Redeem the magic link token
/// let session = try await flow.redeem(token: magicLinkToken)
/// // session.sessionToken is now available for CookieAuth
/// ```
public final class MagicLinkFlow: Sendable {
    private let baseURL: String
    private let userAgent: String
    private let transport: any Transport

    /// The response from creating a session (requesting a magic link).
    public struct PendingSession: Codable, Sendable {
        /// The pending token returned by CreateSession.
        public let pendingToken: String
    }

    /// The response from redeeming a magic link.
    public struct RedeemResult: Codable, Sendable {
        /// The session token to use with CookieAuth.
        public let sessionToken: String

        /// Whether the user needs to complete signup (new account).
        public let requiresSignupCompletion: Bool
    }

    /// The response from completing signup.
    public struct SignupResult: Codable, Sendable {
        /// The user's name after signup completion.
        public let name: String
    }

    /// Creates a MagicLinkFlow.
    ///
    /// - Parameters:
    ///   - baseURL: The Fizzy API base URL (default: `https://fizzy.do`).
    ///   - userAgent: Required User-Agent identifying your app.
    ///   - transport: Optional custom transport (for testing).
    public init(
        baseURL: String = FizzyConfig.defaultBaseURL,
        userAgent: String,
        transport: (any Transport)? = nil
    ) {
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        self.userAgent = userAgent
        self.transport = transport ?? URLSessionTransport()
    }

    /// Step 1: Creates a session by requesting a magic link email.
    ///
    /// - Parameter email: The user's email address.
    /// - Returns: A `PendingSession` with the pending token.
    public func start(email: String) async throws -> PendingSession {
        let url = "\(baseURL)/sessions.json"

        guard let requestURL = URL(string: url) else {
            throw FizzyError.usage(message: "Invalid URL: \(url)", hint: nil)
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let body = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await transport.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FizzyError.network(message: "Invalid response type", cause: nil)
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw FizzyError.fromHTTPResponse(
                status: httpResponse.statusCode, data: data,
                headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
                requestId: httpResponse.value(forHTTPHeaderField: "X-Request-Id")
            )
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(PendingSession.self, from: data)
    }

    /// Step 3: Redeems a magic link token for a session token.
    ///
    /// - Parameter token: The magic link token from the email.
    /// - Returns: A `RedeemResult` containing the session token.
    public func redeem(token: String) async throws -> RedeemResult {
        let url = "\(baseURL)/sessions/redeem.json"

        guard let requestURL = URL(string: url) else {
            throw FizzyError.usage(message: "Invalid URL: \(url)", hint: nil)
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let body = ["token": token]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await transport.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FizzyError.network(message: "Invalid response type", cause: nil)
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw FizzyError.fromHTTPResponse(
                status: httpResponse.statusCode, data: data,
                headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
                requestId: httpResponse.value(forHTTPHeaderField: "X-Request-Id")
            )
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(RedeemResult.self, from: data)
    }

    /// Completes signup for a new user after magic link redemption.
    ///
    /// Only needed when `RedeemResult.requiresSignupCompletion` is `true`.
    ///
    /// - Parameters:
    ///   - name: The user's display name.
    ///   - sessionToken: The session token from `redeem(token:)`.
    /// - Returns: A `SignupResult` confirming the signup.
    public func completeSignup(name: String, sessionToken: String) async throws -> SignupResult {
        let url = "\(baseURL)/signup/completion.json"

        guard let requestURL = URL(string: url) else {
            throw FizzyError.usage(message: "Invalid URL: \(url)", hint: nil)
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("session_token=\(sessionToken)", forHTTPHeaderField: "Cookie")

        let body = ["name": name]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await transport.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FizzyError.network(message: "Invalid response type", cause: nil)
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw FizzyError.fromHTTPResponse(
                status: httpResponse.statusCode, data: data,
                headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
                requestId: httpResponse.value(forHTTPHeaderField: "X-Request-Id")
            )
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(SignupResult.self, from: data)
    }
}
