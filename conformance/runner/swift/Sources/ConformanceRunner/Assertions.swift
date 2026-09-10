import ConformanceSupport
import Fizzy
import Foundation

/// Outcome of a single conformance test.
struct TestResult {
    let passed: Bool
    let message: String

    static func fail(_ message: String) -> TestResult {
        TestResult(passed: false, message: message)
    }

    static let pass = TestResult(passed: true, message: "All assertions passed")
}

/// Maps a FizzyError onto the conformance error-code vocabulary shared by
/// every runner (auth_required, not_found, ...).
func conformanceCode(_ error: FizzyError) -> String {
    switch error {
    case .auth: "auth_required"
    case .forbidden: "forbidden"
    case .notFound: "not_found"
    case .rateLimit: "rate_limit"
    case .validation: "validation"
    case .api: "api_error"
    case .network: "network"
    case .usage: "usage"
    case .ambiguous: "ambiguous"
    }
}

/// Evaluates every assertion in the fixture against the recorded transport
/// traffic and dispatch outcome.
func evaluateAssertions(
    _ tc: TestCase,
    transport: ScriptedTransport,
    caughtError: FizzyError?,
    httpStatus: Int?,
    dispatch: DispatchResult
) -> TestResult {
    let captured = transport.capturedRequests
    let requestCount = captured.count

    // A fixture that queues responses is testing a wire operation, so one must
    // have happened. Every invariant below is guarded on having captured a
    // request, so an operation short-circuited before the transport would slip
    // through all of them and pass on a bare noError assertion.
    //
    // An EMPTY queue is the deliberate no-request case: the HTTPS-enforcement
    // fixture makes no call at all, and says so with requestCount 0.
    if !tc.responses.isEmpty, captured.isEmpty {
        return .fail("fixture queues \(tc.responses.count) mock response(s) but the operation made no request — it never reached the transport")
    }

    // Requests that follow a rel="next" link are governed by the LINK
    // invariant below instead: they go where the previous response SAID to go.
    let linkFollowers: Set<Int> = Set(
        tc.responses.enumerated().compactMap { i, mock in
            mock.linkHeader.flatMap(nextLinkTarget) != nil ? i + 1 : nil
        }
    )

    // Implicit METHOD invariant: the scripted transport answers any verb, so a
    // wrong-verb request (a PATCH regressing to POST) would consume a queued
    // response silently. Every hop — retries repeat the verb and link
    // followers are GETs of a GET.
    let fixtureMethod = tc.fixtureMethod.uppercased()
    if !fixtureMethod.isEmpty {
        for (i, request) in captured.enumerated() where request.method != fixtureMethod {
            return .fail("Expected request \(i) to use method \(fixtureMethod), got \(request.method)")
        }
    }

    // Implicit PATH invariant, for the same reason: the transport answers any
    // URL, so an operation aimed at the wrong endpoint consumes the queued
    // responses and passes its retry, status and auth assertions against a
    // resource the fixture never named. Every non-follower hop; the explicit
    // requestPath assertion below then pins the first request exactly, .json
    // and all.
    if !tc.fixturePath.isEmpty, !captured.isEmpty {
        let params = (tc.pathParams ?? [:]).compactMapValues(\.wireString)
        switch renderFixturePath(tc.fixturePath, params) {
        case .unsubstituted(let name):
            return .fail("fixture path \"\(tc.fixturePath)\" has no usable pathParams entry for \"\(name)\"")
        case .rendered(let expected):
            for (i, request) in captured.enumerated() where !linkFollowers.contains(i) {
                if !requestPathMatches(request.path, fixturePath: expected) {
                    return .fail("Expected request \(i) at path \(expected), got \(request.path)")
                }
            }
        }
    }

    // Implicit LINK invariant: a response that advertises rel="next" says
    // exactly which URL to fetch, so the following request must be that URL —
    // query string included. Only constrains a hop that actually happened: a
    // walk stopped by a cap, or a link the SDK is meant to refuse
    // (cross-origin, protocol downgrade), simply has no following request.
    for (i, mock) in tc.responses.enumerated() where i + 1 < captured.count {
        guard let target = mock.linkHeader.flatMap(nextLinkTarget) else { continue }
        let follower = captured[i + 1]
        let resolved = URL(string: target, relativeTo: follower.request.url)
        let wanted = resolved.map { url -> String in
            guard let query = url.query, !query.isEmpty else { return url.path }
            return "\(url.path)?\(query)"
        } ?? target
        if follower.pathAndQuery != wanted {
            return .fail("Response \(i) advertised rel=\"next\" \(target), so request \(i + 1) must fetch \(wanted), got \(follower.pathAndQuery)")
        }
    }

    for assertion in tc.assertions {
        switch assertion.type {
        case "requestCount":
            guard let expected = assertion.expected?.intValue.map(Int.init) else {
                return .fail("requestCount assertion missing expected value")
            }
            // Exact: a lower bound would make the cap assertions vacuous in the
            // direction that matters, passing an SDK that walked every page.
            if requestCount != expected {
                return .fail("Expected \(expected) requests, got \(requestCount)")
            }

        case "delayBetweenRequests":
            // Delegated to ConformanceSupport so the bounds branches are
            // unit-tested; `min` wins, `expected` is the older spelling.
            let minimum = assertion.min ?? assertion.expected?.intValue.map(Int.init)
            if let failure = checkDelayGaps(captured.map(\.monotonicMs), minDelayMs: minimum.map(Double.init)) {
                return .fail(failure)
            }

        case "statusCode":
            guard let expected = assertion.expected?.intValue.map(Int.init) else {
                return .fail("statusCode assertion missing expected value")
            }
            guard let actual = httpStatus else {
                return .fail("Expected status code \(expected), but got no response")
            }
            if actual != expected {
                return .fail("Expected status code \(expected), got \(actual)")
            }

        case "noError":
            if let caughtError {
                return .fail("Expected no error, got \(conformanceCode(caughtError)): \(caughtError.message)")
            }

        case "errorCode":
            guard let expected = assertion.expected?.stringValue else {
                return .fail("errorCode assertion missing expected value")
            }
            guard let caughtError else {
                return .fail("Expected error code \"\(expected)\", but got no error")
            }
            let actual = conformanceCode(caughtError)
            if actual != expected {
                return .fail("Expected error code \"\(expected)\", got \"\(actual)\"")
            }

        case "errorField":
            let fieldPath = assertion.fieldPath
            guard let caughtError else {
                return .fail("Expected error field \(fieldPath), but got no error")
            }
            guard let expected = assertion.expected?.stringValue else {
                return .fail("errorField assertion missing expected value")
            }
            switch fieldPath {
            case "requestId":
                if caughtError.requestId != expected {
                    return .fail("Expected error.requestId = \"\(expected)\", got \(caughtError.requestId.map { "\"\($0)\"" } ?? "nil")")
                }
            default:
                return .fail("Unknown error field: \(fieldPath)")
            }

        case "errorMessage":
            guard let expected = assertion.expected?.stringValue else {
                return .fail("errorMessage assertion missing expected value")
            }
            guard let caughtError else {
                return .fail("Expected error message containing \"\(expected)\", but got no error")
            }
            if !caughtError.message.contains(expected) {
                return .fail("Expected error message containing \"\(expected)\", got \"\(caughtError.message)\"")
            }

        case "headerPresent":
            let headerName = assertion.fieldPath
            guard let last = captured.last else {
                return .fail("headerPresent \(headerName): no requests recorded")
            }
            let actual = last.header(headerName)
            if actual == nil || actual?.isEmpty == true {
                return .fail("Expected header \(headerName) present on the request, but it was empty or missing")
            }

        case "headerValue", "headerInjected":
            let headerName = assertion.fieldPath
            guard let expected = assertion.expected?.stringValue else {
                return .fail("\(assertion.type) assertion missing expected value")
            }
            guard let last = captured.last else {
                return .fail("\(assertion.type) \(headerName): no requests recorded")
            }
            let actual = last.header(headerName)
            // Content-Type may carry a charset parameter.
            let matches: Bool = if headerName.lowercased() == "content-type" {
                actual?.lowercased().hasPrefix(expected.lowercased()) ?? false
            } else {
                actual == expected
            }
            if !matches {
                return .fail("Expected header \(headerName)=\"\(expected)\" on the request, got \(actual.map { "\"\($0)\"" } ?? "nil")")
            }

        case "requestPath":
            // The FIRST request: the initial request, not a retry or a
            // followed link. Exact, .json and all — the implicit invariant
            // above already allowed the suffix on every hop; this is the
            // fixture pinning the spelling.
            guard let expected = assertion.expected?.stringValue else {
                return .fail("requestPath assertion missing expected value")
            }
            guard let first = captured.first else {
                return .fail("requestPath: no requests recorded")
            }
            if first.path != expected {
                return .fail("Expected request path \"\(expected)\", got \"\(first.path)\"")
            }

        case "requestQueryParam":
            let name = assertion.fieldPath
            guard let first = captured.first else {
                return .fail("requestQueryParam \(name): no requests recorded")
            }
            let actual = first.queryItems.filter { $0.name == name }.map { $0.value ?? "" }
            if let expectedList = assertion.expected?.arrayValue {
                let expected = expectedList.compactMap(\.wireString)
                if actual != expected {
                    return .fail("Expected query param \(name) = \(expected), got \(actual)")
                }
            } else {
                guard let expected = assertion.expected?.wireString else {
                    return .fail("requestQueryParam assertion missing expected value")
                }
                if actual.first != expected {
                    return .fail("Expected query param \(name) = \"\(expected)\", got \(actual.first.map { "\"\($0)\"" } ?? "nil")")
                }
            }

        case "requestBodyField":
            guard let field = assertion.expected?.stringValue else {
                return .fail("requestBodyField assertion missing expected value")
            }
            guard let last = captured.last else {
                return .fail("requestBodyField \(field): no requests recorded")
            }
            guard let body = last.bodyJSON?.objectValue else {
                return .fail("requestBodyField \(field): request has no JSON object body")
            }
            if body[field] == nil {
                return .fail("Expected field \"\(field)\" in request body, got keys \(body.keys.sorted())")
            }

        case "urlOrigin":
            if assertion.expected?.stringValue == "rejected", requestCount > 1 {
                return .fail("Expected the Link to be rejected (1 request), but \(requestCount) requests were made")
            }

        case "responseMeta":
            let fieldPath = assertion.fieldPath
            guard fieldPath == "truncated" else {
                return .fail("Unknown response meta field: \(fieldPath)")
            }
            guard let expected = assertion.expected?.boolValue else {
                return .fail("responseMeta.truncated assertion needs a boolean expected value")
            }
            guard let actual = dispatch.truncated else {
                return .fail("responseMeta.truncated: the operation returned no list")
            }
            if actual != expected {
                return .fail("Expected meta.truncated = \(expected), got \(actual)")
            }

        default:
            // The schema also names responseBody and requestScheme. Neither
            // has an observation this runner records, and a pass on an
            // assertion it cannot check is the false green the suite exists
            // to remove — so they fail here until a fixture needs them and the
            // observation is added, rather than being skipped.
            return .fail("Unsupported assertion type: \(assertion.type)")
        }
    }

    return .pass
}
