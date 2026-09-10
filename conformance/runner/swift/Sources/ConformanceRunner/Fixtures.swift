import Foundation

/// Arbitrary JSON value that preserves 64-bit integer precision.
///
/// Fixture bodies and parameters carry IDs beyond 2^53 (integer-precision.json),
/// so numbers are decoded as `Int64` first and only fall back to `Double` when
/// the value is not an integer. Re-encoding an `.int` therefore round-trips the
/// exact digits to the wire.
indirect enum JSON: Codable, Equatable, Sendable {
    case null
    case bool(Bool)
    case int(Int64)
    case double(Double)
    case string(String)
    case array([JSON])
    case object([String: JSON])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int64.self) {
            self = .int(i)
        } else if let d = try? container.decode(Double.self) {
            self = .double(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let a = try? container.decode([JSON].self) {
            self = .array(a)
        } else if let o = try? container.decode([String: JSON].self) {
            self = .object(o)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unsupported JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let b): try container.encode(b)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        case .string(let s): try container.encode(s)
        case .array(let a): try container.encode(a)
        case .object(let o): try container.encode(o)
        }
    }

    // MARK: - Accessors

    var intValue: Int64? {
        switch self {
        case .int(let i): i
        case .double(let d): d == d.rounded() ? Int64(exactly: d.rounded()) : nil
        default: nil
        }
    }

    var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let b) = self { return b }
        return nil
    }

    var arrayValue: [JSON]? {
        if case .array(let a) = self { return a }
        return nil
    }

    var objectValue: [String: JSON]? {
        if case .object(let o) = self { return o }
        return nil
    }

    /// The value as it would be written into a path or query: strings
    /// verbatim, integers with every digit, anything else refused.
    var wireString: String? {
        switch self {
        case .string(let s): s
        case .int(let i): String(i)
        default: nil
        }
    }

    /// Display form used in failure messages.
    var display: String {
        switch self {
        case .null: "null"
        case .bool(let b): String(b)
        case .int(let i): String(i)
        case .double(let d): String(d)
        case .string(let s): "\"\(s)\""
        case .array, .object:
            (try? String(data: JSONEncoder().encode(self), encoding: .utf8) ?? "?") ?? "?"
        }
    }

    /// Serializes this value to JSON `Data`.
    func serialized() throws -> Data {
        try JSONEncoder().encode(self)
    }

    /// Parses raw data into a JSON value, or nil when not valid JSON.
    static func parse(_ data: Data) -> JSON? {
        try? JSONDecoder().decode(JSON.self, from: data)
    }
}

// MARK: - Fixture models

/// One conformance test case, matching conformance/schema.json. `name`,
/// `operation` and `assertions` are required, as the schema says: a case
/// whose `assertions` key is misspelled would otherwise load with none and
/// pass on the implicit checks alone.
struct TestCase: Decodable, Sendable {
    let name: String
    let operation: String
    private let method: String?
    private let path: String?
    let pathParams: [String: JSON]?
    let queryParams: [String: JSON]?
    let requestBody: [String: JSON]?
    let configOverrides: ConfigOverrides?
    private let mockResponses: [MockResponse]?
    let assertions: [Assertion]

    var fixtureMethod: String { method ?? "" }
    var fixturePath: String { path ?? "" }
    var responses: [MockResponse] { mockResponses ?? [] }
    /// Whether the fixture stated a queue at all. An EMPTY queue is a
    /// deliberate declaration (the HTTPS-enforcement case makes no request);
    /// an absent key is a malformed fixture, and collapsing the two lets one
    /// through as a test that exercises nothing.
    var declaresMockResponses: Bool { mockResponses != nil }

    func hasAssertion(_ type: String) -> Bool {
        assertions.contains { $0.type == type }
    }

    /// Whether the case exercises pagination: several responses with a `Link`
    /// header to follow, or an assertion about where that header points. The
    /// same heuristic as the Go, Kotlin and Rust runners.
    var followsLinks: Bool {
        (responses.count > 1 && responses.contains(where: \.hasLinkHeader)) || hasAssertion("urlOrigin")
    }

    /// The item count of the first queued page, when it is a non-empty array.
    var firstPageItemCount: Int? {
        guard let count = responses.first?.body?.arrayValue?.count, count > 0 else { return nil }
        return count
    }
}

struct ConfigOverrides: Decodable, Sendable {
    let baseUrl: String?
    let maxPages: Int?
    let maxItems: Int?
    /// Overrides the client-wide retry cap as a TOTAL attempt count. Optional
    /// because 0 is the value this override exists for — "no retries, exactly
    /// one attempt" — and it must stay distinguishable from absent. Swift
    /// exposes no numeric cap, so the runner maps it onto `enableRetry`; see
    /// `retryEnabled(forMaxRetries:)`.
    let maxRetries: Int?
}

struct MockResponse: Decodable, Sendable {
    let status: Int?
    private let headers: [String: String]?
    let body: JSON?
    private let delay: Int?

    var allHeaders: [String: String] { headers ?? [:] }
    var delayMs: Int { delay ?? 0 }
    var hasLinkHeader: Bool {
        allHeaders.keys.contains { $0.lowercased() == "link" }
    }
    var linkHeader: String? {
        allHeaders.first { $0.key.lowercased() == "link" }?.value
    }
}

struct Assertion: Decodable, Sendable {
    let type: String
    let expected: JSON?
    private let path: String?
    let min: Int?

    var fieldPath: String { path ?? "" }
}
