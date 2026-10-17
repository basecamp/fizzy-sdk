import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Signs in without a password: Fizzy emails a code, and the person types it back.
///
/// The two steps are one exchange as far as Fizzy is concerned. Creating the session answers a
/// pending authentication token and sets it as the `pending_authentication_token` cookie;
/// redeeming the code has to send that cookie back or the code is refused. The flow keeps the
/// token between the calls, sends it as an explicit `Cookie` header rather than leaving it to a
/// cookie store, and hands it out for a caller that finishes in another process — a CLI that
/// prompts for the code on its next run — through ``pendingToken`` and
/// ``resume(pendingToken:baseURL:userAgent:transport:)``.
///
/// ```swift
/// let flow = MagicLinkFlow(userAgent: "my-app/1.0")
///
/// // Step 1: Fizzy emails a sign-in code.
/// try await flow.start(emailAddress: "user@example.com")
///
/// // Step 2: the person reads the code out of their email.
///
/// // Step 3: redeem it for a session token.
/// let session = try await flow.redeem(code: code)
/// let client = FizzyClient(auth: CookieAuth(sessionToken: session.sessionToken), userAgent: "my-app/1.0")
///
/// // A new account finishes signing up with a name.
/// if session.requiresSignupCompletion {
///     try await flow.completeSignup(fullName: "Jane Doe", sessionToken: session.sessionToken)
/// }
/// ```
///
/// Every request goes through the generated `SessionsService`, so its paths, bodies and answers
/// are the model's: `POST /session.json`, `POST /session/magic_link.json` and
/// `POST /signup/completion.json`.
public final class MagicLinkFlow: @unchecked Sendable {
    /// The cookie a pending sign-in is carried in between creating the session and redeeming the code.
    public static let pendingCookie = "pending_authentication_token"

    private let baseURL: String
    private let userAgent: String
    private let transport: any Transport
    private let lock = NSLock()
    private var pending: String?

    /// Creates a MagicLinkFlow.
    ///
    /// - Parameters:
    ///   - baseURL: The Fizzy base URL (default: `https://fizzy.do`). It must use HTTPS, except on
    ///     localhost.
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

    /// A flow that picks up where another left off, with the pending token that one handed out
    /// through ``pendingToken``.
    public static func resume(
        pendingToken: String,
        baseURL: String = FizzyConfig.defaultBaseURL,
        userAgent: String,
        transport: (any Transport)? = nil
    ) -> MagicLinkFlow {
        let flow = MagicLinkFlow(baseURL: baseURL, userAgent: userAgent, transport: transport)
        flow.setPending(pendingToken)
        return flow
    }

    /// The token a pending sign-in is waiting on, for a caller that finishes the flow in another
    /// process; nil before ``start(emailAddress:)``.
    public var pendingToken: String? {
        lock.withLock { pending }
    }

    /// Step 1: asks Fizzy to email a sign-in code to the address, and keeps the pending token the
    /// answer carries for ``redeem(code:)``.
    ///
    /// - Parameter emailAddress: The address the code goes to.
    /// - Returns: The pending authentication Fizzy answered.
    @discardableResult
    public func start(emailAddress: String) async throws -> PendingAuthentication {
        let pendingAuthentication = try await client(auth: CookieHeaderAuth(cookie: nil))
            .sessions.create(req: CreateSessionRequest(emailAddress: emailAddress))
        setPending(pendingAuthentication.pendingAuthenticationToken)
        return pendingAuthentication
    }

    /// Step 3: sends the code back with the pending token, and answers the session Fizzy signed in.
    ///
    /// Without a pending token — no ``start(emailAddress:)`` before it, and none given to
    /// ``resume(pendingToken:baseURL:userAgent:transport:)`` — there is nothing to redeem against,
    /// and it throws a usage error without sending anything.
    ///
    /// - Parameter code: The code from the email.
    /// - Returns: The session token, for ``CookieAuth``, and whether signup is still to complete.
    public func redeem(code: String) async throws -> SessionAuthorization {
        guard let pending = pendingToken else {
            throw FizzyError.usage(
                message: "No sign-in is pending",
                hint: "Call start(emailAddress:) first, or resume with the pending token")
        }
        return try await client(auth: CookieHeaderAuth(cookie: (Self.pendingCookie, pending)))
            .sessions.redeemMagicLink(req: RedeemMagicLinkRequest(code: code))
    }

    /// Completes signup for a new person after the code is redeemed. Only needed when
    /// ``SessionAuthorization/requiresSignupCompletion`` is true. Fizzy answers 201 with no body.
    ///
    /// - Parameters:
    ///   - fullName: The person's full name.
    ///   - sessionToken: The session token ``redeem(code:)`` answered.
    public func completeSignup(fullName: String, sessionToken: String) async throws {
        try await client(auth: CookieHeaderAuth(cookie: ("session_token", sessionToken)))
            .sessions.completeSignup(req: CompleteSignupRequest(fullName: fullName))
    }

    // MARK: - Private

    private func setPending(_ token: String) {
        lock.withLock { pending = token }
    }

    private func client(auth: CookieHeaderAuth) -> FizzyClient {
        FizzyClient(auth: auth, userAgent: userAgent, config: FizzyConfig(baseURL: baseURL), transport: transport)
    }
}

/// Sends one cookie, or none, as an explicit `Cookie` header, and keeps any cookie store out of
/// the request: what goes out is exactly what the flow decided, whatever a shared
/// `URLSession` has stored for the origin.
struct CookieHeaderAuth: AuthStrategy {
    let cookie: (name: String, value: String)?

    func authenticate(_ request: inout URLRequest) async throws {
        request.httpShouldHandleCookies = false
        if let cookie {
            request.setValue("\(cookie.name)=\(Self.encode(cookie.value))", forHTTPHeaderField: "Cookie")
        }
    }

    /// A cookie value escaped as Rack unescapes it: everything but ASCII letters, digits and
    /// `-._~` is percent-encoded, so a `;` or `,` in a token cannot end the cookie early.
    static func encode(_ value: String) -> String {
        var allowed = CharacterSet()
        allowed.insert(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}
