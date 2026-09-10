import Fizzy
import Foundation

/// One outbound request captured by the scripted transport.
struct CapturedRequest: @unchecked Sendable {
    /// The full URLRequest as handed to the transport (headers, body, method).
    let request: URLRequest
    /// Monotonic capture time in milliseconds (DispatchTime, immune to
    /// wall-clock adjustments), for delayBetweenRequests assertions.
    let monotonicMs: UInt64

    var method: String { request.httpMethod?.uppercased() ?? "" }
    var path: String { request.url?.path ?? "" }
    /// Path WITH the query string. `path` alone cannot tell `/boards.json`
    /// from `/boards.json?page=2`, so pagination that refetched page 1 would
    /// be answered from the queue with page 2's body and pass.
    var pathAndQuery: String {
        guard let url = request.url else { return "" }
        guard let query = url.query, !query.isEmpty else { return url.path }
        return "\(url.path)?\(query)"
    }
    /// Decoded query items, in wire order.
    var queryItems: [URLQueryItem] {
        request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
    }
    var bodyJSON: JSON? { request.httpBody.flatMap { JSON.parse($0) } }

    /// Case-insensitive request-header lookup.
    func header(_ name: String) -> String? {
        request.value(forHTTPHeaderField: name)
    }
}

/// Transport that answers each request from the fixture's scripted response
/// queue, in order, recording every request it sees.
///
/// This is the SDK's public `Transport` seam — no `@testable` anywhere — so
/// the run exercises `HTTPClient` and `BaseService` exactly as a caller would.
/// The Go, Kotlin and Rust runners do the same through a loopback server or
/// mock engine; nothing here ever dials.
final class ScriptedTransport: Transport, @unchecked Sendable {
    private let lock = NSLock()
    private let responses: [MockResponse]
    /// When any fixture response carries a Link header the SDK may paginate
    /// past the scripted queue; answer the overflow with an empty terminal page
    /// instead of an error, the rule every other runner applies.
    private let pagesPastTheQueue: Bool
    private var captured: [CapturedRequest] = []
    private var served = 0

    init(responses: [MockResponse]) {
        self.responses = responses
        self.pagesPastTheQueue = responses.contains(where: \.hasLinkHeader)
    }

    var capturedRequests: [CapturedRequest] {
        lock.withLock { captured }
    }

    /// The fixture index of the last consumed queue entry, or nil when no
    /// entry (or only synthetic overflow pages) served the final request.
    var lastConsumedIndex: Int? {
        lock.withLock {
            let last = served - 1
            return (last >= 0 && last < responses.count) ? last : nil
        }
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let index: Int? = lock.withLock {
            captured.append(CapturedRequest(
                request: request,
                monotonicMs: DispatchTime.now().uptimeNanoseconds / 1_000_000
            ))
            let i = served
            served += 1
            return i < responses.count ? i : nil
        }

        let url = request.url ?? URL(string: FizzyConfig.defaultBaseURL)!

        guard let index else {
            if pagesPastTheQueue {
                return (
                    Data("[]".utf8),
                    HTTPURLResponse(
                        url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                        headerFields: ["Content-Type": "application/json"])!
                )
            }
            return (
                Data(#"{"error": "No more mock responses"}"#.utf8),
                HTTPURLResponse(
                    url: url, statusCode: 500, httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"])!
            )
        }

        let mock = responses[index]

        if mock.delayMs > 0 {
            try await Task.sleep(nanoseconds: UInt64(mock.delayMs) * 1_000_000)
        }

        var headerFields = ["Content-Type": "application/json"]
        for (key, value) in mock.allHeaders {
            headerFields[key] = value
        }

        let body: Data
        if let fixtureBody = mock.body, fixtureBody != .null {
            body = try fixtureBody.serialized()
        } else {
            body = Data()
        }

        // The schema guarantees a status on every entry; the runner backstop
        // re-checks before dispatch.
        let response = HTTPURLResponse(
            url: url, statusCode: mock.status ?? 200,
            httpVersion: "HTTP/1.1", headerFields: headerFields)!
        return (body, response)
    }
}
