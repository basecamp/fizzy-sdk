import Foundation

/// Metadata about a paginated list response.
public struct ListMeta: Sendable, Equatable {
    /// True when results were truncated (by `maxItems` or page safety cap).
    public let truncated: Bool

    public init(truncated: Bool = false) {
        self.truncated = truncated
    }
}

/// Options for controlling pagination behavior.
public struct PaginationOptions: Sendable {
    /// Maximum number of items to return across all pages.
    /// When nil or 0, all pages are fetched.
    public let maxItems: Int?

    public init(maxItems: Int? = nil) {
        self.maxItems = maxItems
    }
}

/// A paginated list result that conforms to `RandomAccessCollection`.
///
/// Acts like a Swift `Array` -- supports `for-in`, `.count`, subscripting,
/// `.map()`, `.filter()`, and all other collection operations. The `.meta`
/// property provides pagination metadata.
///
/// ```swift
/// let cards = try await client.cards.list(boardId: 1)
/// print("Showing \(cards.count) cards")
/// for card in cards { print(card.title) }
/// let titles = cards.map(\.title)
/// ```
public struct ListResult<Element: Sendable>: Sendable {
    /// The underlying items.
    public let items: [Element]
    /// Pagination metadata.
    public let meta: ListMeta

    /// Creates a new list result.
    public init(_ items: [Element], meta: ListMeta) {
        self.items = items
        self.meta = meta
    }

    /// Creates an empty list result.
    public init() {
        self.items = []
        self.meta = ListMeta()
    }
}

// MARK: - RandomAccessCollection

extension ListResult: RandomAccessCollection {
    public typealias Index = Int

    public var startIndex: Int { items.startIndex }
    public var endIndex: Int { items.endIndex }

    public subscript(position: Int) -> Element {
        items[position]
    }
}

// MARK: - Pagination Utilities

/// Parses the next URL from a Link header.
///
/// Looks for `rel="next"` in the header value.
///
/// - Parameter linkHeader: The Link header value.
/// - Returns: The URL for the next page, or nil if not found.
func parseNextLink(_ linkHeader: String?) -> String? {
    guard let linkHeader, !linkHeader.isEmpty else { return nil }

    for part in linkHeader.split(separator: ",") {
        let trimmed = part.trimmingCharacters(in: .whitespaces)
        if trimmed.contains("rel=\"next\"") {
            guard let start = trimmed.firstIndex(of: "<"),
                  let end = trimmed.firstIndex(of: ">"),
                  start < end
            else { continue }
            return String(trimmed[trimmed.index(after: start)..<end])
        }
    }
    return nil
}

/// Resolves a possibly-relative URL against a base URL.
///
/// If target is already absolute, it is returned unchanged.
func resolveURL(base: String, target: String) -> String {
    guard let baseURL = URL(string: base) else { return target }
    guard let resolved = URL(string: target, relativeTo: baseURL) else { return target }
    return resolved.absoluteString
}

/// Checks whether two absolute URLs share the same origin (scheme + host + port).
func isSameOrigin(_ a: String, _ b: String) -> Bool {
    guard let urlA = URLComponents(string: a),
          let urlB = URLComponents(string: b)
    else { return false }

    return urlA.scheme == urlB.scheme
        && urlA.host == urlB.host
        && (urlA.port ?? defaultPort(for: urlA.scheme)) == (urlB.port ?? defaultPort(for: urlB.scheme))
}

private func defaultPort(for scheme: String?) -> Int? {
    switch scheme {
    case "https": 443
    case "http": 80
    default: nil
    }
}
