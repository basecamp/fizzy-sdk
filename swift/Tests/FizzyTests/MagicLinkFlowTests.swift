import Foundation
import Testing
@testable import Fizzy
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Answers each request with the next scripted reply, and records what was sent.
final class ScriptedMagicLinkTransport: Transport, @unchecked Sendable {
    struct Reply {
        let status: Int
        let body: String
    }

    private let lock = NSLock()
    private var replies: [Reply]
    private(set) var requests: [URLRequest] = []

    init(_ replies: Reply...) {
        self.replies = replies
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let reply: Reply = lock.withLock {
            requests.append(request)
            return replies.isEmpty ? Reply(status: 500, body: "") : replies.removeFirst()
        }
        let response = HTTPURLResponse(
            url: request.url!, statusCode: reply.status, httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"])!
        return (Data(reply.body.utf8), response)
    }

    func json(_ index: Int) throws -> [String: Any] {
        let body = lock.withLock { requests[index].httpBody } ?? Data()
        return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    func request(_ index: Int) -> URLRequest {
        lock.withLock { requests[index] }
    }
}

@Suite("MagicLinkFlow")
struct MagicLinkFlowTests {
    private let created = ScriptedMagicLinkTransport.Reply(status: 201, body: #"{"pending_authentication_token":"pend;1"}"#)
    private let signedIn = ScriptedMagicLinkTransport.Reply(
        status: 200, body: #"{"session_token":"sess-1","requires_signup_completion":true}"#)

    @Test("Creating the session posts the email address to /session.json and keeps the 201's pending token")
    func createsTheSession() async throws {
        let transport = ScriptedMagicLinkTransport(created)
        let flow = MagicLinkFlow(userAgent: "test/1.0", transport: transport)

        let pending = try await flow.start(emailAddress: "jane@example.com")

        let request = transport.request(0)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://fizzy.do/session.json")
        #expect(try transport.json(0) as NSDictionary == ["email_address": "jane@example.com"])
        #expect(request.value(forHTTPHeaderField: "Cookie") == nil)
        #expect(pending.pendingAuthenticationToken == "pend;1")
        #expect(flow.pendingToken == "pend;1")
    }

    @Test("Redeeming posts the code to /session/magic_link.json with the pending token as an encoded cookie")
    func redeemsTheCode() async throws {
        let transport = ScriptedMagicLinkTransport(created, signedIn)
        let flow = MagicLinkFlow(userAgent: "test/1.0", transport: transport)
        try await flow.start(emailAddress: "jane@example.com")

        let session = try await flow.redeem(code: "ABC123")

        let request = transport.request(1)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://fizzy.do/session/magic_link.json")
        #expect(try transport.json(1) as NSDictionary == ["code": "ABC123"])
        #expect(request.value(forHTTPHeaderField: "Cookie") == "pending_authentication_token=pend%3B1")
        #expect(request.httpShouldHandleCookies == false)
        #expect(session.sessionToken == "sess-1")
        #expect(session.requiresSignupCompletion)
    }

    @Test("A resumed flow redeems against the pending token it was given")
    func resumes() async throws {
        let transport = ScriptedMagicLinkTransport(signedIn)
        let flow = MagicLinkFlow.resume(pendingToken: "pend-2", userAgent: "test/1.0", transport: transport)

        _ = try await flow.redeem(code: "ABC123")

        #expect(transport.request(0).value(forHTTPHeaderField: "Cookie") == "pending_authentication_token=pend-2")
    }

    @Test("Redeeming with nothing pending is a usage error and sends nothing")
    func redeemsNothingWithoutAPendingToken() async throws {
        let transport = ScriptedMagicLinkTransport()
        let flow = MagicLinkFlow(userAgent: "test/1.0", transport: transport)

        await #expect(throws: FizzyError.self) { try await flow.redeem(code: "ABC123") }
        #expect(transport.requests.isEmpty)
    }

    @Test("A refused code is an auth error")
    func refusedCode() async throws {
        let transport = ScriptedMagicLinkTransport(
            ScriptedMagicLinkTransport.Reply(status: 401, body: #"{"message":"Try another code."}"#))
        let flow = MagicLinkFlow.resume(pendingToken: "pend-2", userAgent: "test/1.0", transport: transport)

        do {
            _ = try await flow.redeem(code: "WRONG1")
            Issue.record("a 401 must throw")
        } catch let error as FizzyError {
            #expect(error.httpStatusCode == 401)
            if case .auth = error {} else { Issue.record("a 401 is an auth error, got \(error)") }
            #expect(transport.requests.count == 1)
        }
    }

    @Test("Completing signup posts the full name with an encoded session cookie and takes the empty 201")
    func completesSignup() async throws {
        let transport = ScriptedMagicLinkTransport(ScriptedMagicLinkTransport.Reply(status: 201, body: ""))
        let flow = MagicLinkFlow(userAgent: "test/1.0", transport: transport)

        try await flow.completeSignup(fullName: "Jane Doe", sessionToken: "sess=1")

        let request = transport.request(0)
        #expect(request.url?.absoluteString == "https://fizzy.do/signup/completion.json")
        #expect(try transport.json(0) as NSDictionary == ["full_name": "Jane Doe"])
        #expect(request.value(forHTTPHeaderField: "Cookie") == "session_token=sess%3D1")
    }
}
