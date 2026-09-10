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
/// Deliberately tolerant of the surrounding syntax (multiple comma-separated
/// links, arbitrary parameter order and spacing) and strict about the target
/// itself, which is returned verbatim between the angle brackets. This
/// function decides which requests the link-follower exemption covers, so a
/// parser here that is stricter than the SDK's does not merely miss a bug — it
/// invents one, by holding a correctly followed link to the fixture's first
/// path.
public func nextLinkTarget(_ headerValue: String) -> String? {
    for link in headerValue.split(separator: ",") {
        let parts = link.split(separator: ";")
        guard let head = parts.first?.trimmingCharacters(in: .whitespaces),
              let target = angleBracketedTarget(head),
              parts.dropFirst().contains(where: { isRelNext($0) })
        else { continue }
        return target
    }
    return nil
}

/// The leftmost non-empty `<…>` span in `part`, matching `/<([^>]+)>/`.
///
/// Mirrors `parseNextLink` in the SDK: scan for `<`, then for the first `>`
/// AFTER it, and skip an empty `<>` because `[^>]+` requires a character.
func angleBracketedTarget(_ part: String) -> String? {
    var cursor = part.startIndex

    while let start = part[cursor...].firstIndex(of: "<") {
        let contentStart = part.index(after: start)
        guard let end = part[contentStart...].firstIndex(of: ">") else { return nil }

        if end > contentStart {
            return String(part[contentStart..<end])
        }
        cursor = contentStart
    }

    return nil
}

private func isRelNext(_ parameter: Substring) -> Bool {
    let cleaned = parameter
        .trimmingCharacters(in: .whitespaces)
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "\"", with: "")
        .lowercased()
    return cleaned == "rel=next"
}
