import Foundation

/// Rendering a fixture's declared `path` template against its `pathParams`,
/// so the runner can hold an operation to the endpoint the fixture names.

/// The outcome of rendering a path template.
public enum RenderedPath: Equatable, Sendable {
    case rendered(String)
    /// A `{placeholder}` the params did not supply. Fail-closed: an
    /// unsubstituted template can never equal a real request path, but saying
    /// WHICH parameter is missing is the difference between a fixable fixture
    /// and a puzzling mismatch.
    case unsubstituted(String)
}

/// Substitutes `{name}` placeholders in a fixture path template.
///
/// Values arrive already stringified by the caller, because a path parameter
/// that is neither a string nor an integer is a fixture bug the dispatch
/// accessors reject first — this function only has to render what survived.
public func renderFixturePath(_ template: String, _ params: [String: String]) -> RenderedPath {
    var out = template
    for (name, value) in params {
        out = out.replacingOccurrences(of: "{\(name)}", with: value)
    }
    if let leftover = firstPlaceholder(in: out) {
        return .unsubstituted(leftover)
    }
    return .rendered(out)
}

/// Names the first `{...}` still present, or nil when the template is fully
/// rendered. Scans rather than using a regex so the target stays dependency-free.
private func firstPlaceholder(in path: String) -> String? {
    guard let open = path.firstIndex(of: "{") else { return nil }
    let afterOpen = path.index(after: open)
    guard let close = path[afterOpen...].firstIndex(of: "}") else { return nil }
    return String(path[afterOpen..<close])
}

/// Whether an observed request path matches a rendered fixture path.
///
/// EXACT apart from one allowance: Fizzy serves every route with or without a
/// `.json` suffix, the fixtures spell some routes one way and the generated
/// Swift paths spell them the other (`/{accountId}/boards/{boardId}.json` in
/// retry.json against `/999/boards/1` from `BoardsService.get`), so the suffix
/// is stripped from both sides before comparing — the same allowance the Rust
/// runner's route validation makes.
///
/// Never a suffix test: `/999/my/pins.json` ends with `/pins.json`, so a
/// suffix match would wave through an operation that hit a neighbouring
/// endpoint — the very thing this invariant exists to catch.
public func requestPathMatches(_ actual: String, fixturePath: String) -> Bool {
    withoutJSONSuffix(actual) == withoutJSONSuffix(fixturePath)
}

/// A path with its `.json` suffix removed, when it carries one.
public func withoutJSONSuffix(_ path: String) -> String {
    path.hasSuffix(".json") ? String(path.dropLast(".json".count)) : path
}

/// Extracts the `rel="next"` target from a `Link` header value, or nil when the
/// header names no next page.
///
/// A line-for-line mirror of the SDK's `parseNextLink` (swift/Sources/Fizzy/
/// Pagination.swift): split on commas, trim, require the literal `rel="next"`
/// somewhere in the part, and take the span between the FIRST `<` and the
/// FIRST `>` of the part, skipping the part when they are not in that order.
/// It is deliberately no more and no less tolerant than the SDK. This function
/// decides which requests are exempt from the path invariant as link
/// followers, and which advertised URL the link invariant holds them to: a
/// parser stricter than the SDK's holds a correctly followed link to the
/// fixture's first path and fails a correct SDK; one more permissive classifies
/// a header the SDK ignores as a next link, and the exemption it grants then
/// covers a request the SDK never makes for that reason.
public func nextLinkTarget(_ headerValue: String) -> String? {
    guard !headerValue.isEmpty else { return nil }

    for part in headerValue.split(separator: ",") {
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
