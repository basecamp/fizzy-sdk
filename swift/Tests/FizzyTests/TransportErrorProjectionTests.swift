import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import Fizzy

/// A request that fails in transport must not put its URL's query into any
/// rendering of the error. `URLError` carries the failing URL in its
/// `userInfo`, and `String(describing:)` on `.network(message:cause:)` prints
/// it — so a signed query on the request reached the error's description,
/// `debugDescription`, `NSError` bridge, cause chain and the retry hook.
@Suite("Transport error projection")
struct TransportErrorProjectionTests {
    static let secret = "SECRETVALUE"
    static let signedURL = "http://127.0.0.1:1/blob?signature=\(secret)"

    final class RetrySpy: FizzyHooks, @unchecked Sendable {
        private let lock = NSLock()
        private var _errors: [any Error] = []
        var errors: [any Error] { lock.withLock { _errors } }

        func onOperationStart(_ info: OperationInfo) {}
        func onOperationEnd(_ info: OperationInfo, result: OperationResult) {}
        func onRequestStart(_ info: RequestInfo) {}
        func onRequestEnd(_ info: RequestInfo, result: RequestResult) {}
        func onRetry(_ info: RequestInfo, attempt: Int, error: any Error, delaySeconds: TimeInterval) {
            lock.withLock { _errors.append(error) }
        }
    }

    /// Every way a caller or a logger can render an error, walking the
    /// `.network` cause chain and the `NSError` underlying chain.
    static func renderings(of error: any Error, label: String = "error") -> [(String, String)] {
        let nsError = error as NSError
        var out: [(String, String)] = [
            ("\(label) describing", String(describing: error)),
            ("\(label) reflecting", String(reflecting: error)),
            ("\(label) localizedDescription", error.localizedDescription),
            ("\(label) NSError.description", nsError.description),
            ("\(label) NSError.userInfo", String(describing: nsError.userInfo)),
        ]
        if let fizzyError = error as? FizzyError, case .network(_, let cause) = fizzyError, let cause {
            out += renderings(of: cause, label: "\(label).cause")
        }
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            out += renderings(of: underlying, label: "\(label).underlying")
        }
        return out
    }

    static func expectNoSecret(_ error: any Error, _ context: String, sourceLocation: SourceLocation = #_sourceLocation) {
        for (label, text) in renderings(of: error) {
            #expect(!text.contains(secret), "\(context): the signed query leaked into \(label): \(text)", sourceLocation: sourceLocation)
        }
    }

    // Dials a closed port through the shipped URLSession transport, with a
    // two-attempt policy so the retry hook sees the failure too.
    @Test("A transport failure renders no signed query")
    func transportFailureRendersNoSignedQuery() async throws {
        let spy = RetrySpy()
        let client = FizzyClient(
            auth: BearerAuth(tokenProvider: StaticTokenProvider("token")),
            userAgent: "test/1.0",
            config: FizzyConfig(baseURL: "http://127.0.0.1:1", enableRetry: true),
            hooks: spy
        )
        let policy = RetryConfig(maxAttempts: 2, baseDelayMs: 1, backoff: .constant, retryOn: [])

        do {
            _ = try await client.httpClient.performRequest(method: "GET", url: Self.signedURL, retryConfig: policy)
            Issue.record("expected the dial to a closed port to fail")
        } catch {
            guard let fizzyError = error as? FizzyError, case .network(let message, let cause) = fizzyError else {
                Issue.record("expected .network, got \(error)")
                return
            }
            #expect(message == "Network error")
            let urlError = try #require(cause as? URLError, "the cause still classifies as a URLError")
            #expect(urlError.code == .cannotConnectToHost)
            #expect(urlError.failingURL?.absoluteString == "http://127.0.0.1:1/blob", "origin and path survive the projection")
            #expect(String(describing: fizzyError).contains("http://127.0.0.1:1/blob"))
            Self.expectNoSecret(fizzyError, "thrown error")
        }

        #expect(spy.errors.count == 1, "the failed first attempt announces one retry")
        for error in spy.errors {
            #expect((error as? URLError)?.code == .cannotConnectToHost, "onRetry receives the projected transport error")
            Self.expectNoSecret(error, "onRetry error")
        }
    }

    // A Transport that speaks .network wraps its own URLSession error; the
    // projection reaches through it and keeps the transport's message.
    @Test("A transport-spoken .network is projected through its cause")
    func transportSpokenNetworkErrorIsProjectedThroughItsCause() throws {
        let raw = URLError(.timedOut, userInfo: [
            NSURLErrorFailingURLErrorKey: URL(string: Self.signedURL)!,
            NSURLErrorFailingURLStringErrorKey: Self.signedURL,
        ])
        let projected = HTTPClient.projectedTransportError(FizzyError.network(message: "custom transport", cause: raw))

        guard let fizzyError = projected as? FizzyError, case .network(let message, let cause) = fizzyError else {
            Issue.record("expected .network, got \(projected)")
            return
        }
        #expect(message == "custom transport")
        let urlError = try #require(cause as? URLError)
        #expect(urlError.code == .timedOut)
        #expect(urlError.failingURL?.absoluteString == "http://127.0.0.1:1/blob")
        Self.expectNoSecret(projected, "projected transport error")
    }

    // An error that is not a URLError is the transport's own and passes through untouched.
    @Test("A foreign transport error passes through")
    func foreignTransportErrorPassesThrough() {
        struct ForeignTransportError: Error, Equatable { let id: Int }
        let raw = ForeignTransportError(id: 7)
        #expect(HTTPClient.projectedTransportError(raw) as? ForeignTransportError == raw)
    }
}
