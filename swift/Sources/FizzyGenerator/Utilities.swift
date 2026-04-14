import Foundation

// MARK: - String Utilities

/// Converts a snake_case string to lowerCamelCase.
///
/// Splits on `_`, lowercases the first segment, capitalizes only the first
/// character of each subsequent segment and lowercases the rest. Empty
/// segments from consecutive or leading underscores are skipped.
///
/// For strings without underscores (already camelCase), just lowercases
/// the first character.
func toCamelCase(_ str: String) -> String {
    let normalized = str.hasSuffix("[]") ? String(str.dropLast(2)) : str
    let parts = normalized.split(separator: "_", omittingEmptySubsequences: false)
    guard let first = parts.first else { return normalized }
    if parts.count == 1 {
        // No underscores — just lowercase first character
        return lowercaseFirst(String(first))
    }
    let nonEmpty = parts.filter { !$0.isEmpty }
    guard let head = nonEmpty.first else { return str }
    var result = head.lowercased()
    for part in nonEmpty.dropFirst() {
        guard let initial = part.first else { continue }
        result += initial.uppercased()
        result += part.dropFirst().lowercased()
    }
    return result
}

/// Capitalizes the first character.
func capitalize(_ str: String) -> String {
    guard let first = str.first else { return str }
    return first.uppercased() + str.dropFirst()
}

/// Lowercases the first character.
func lowercaseFirst(_ str: String) -> String {
    guard let first = str.first else { return str }
    return first.lowercased() + str.dropFirst()
}

/// Singularization for service/type names (PascalCase or lowercase).
func singularize(_ str: String) -> String {
    if str.hasSuffix("sses") { return String(str.dropLast(2)) }
    if str.hasSuffix("ss") { return str }
    if str.hasSuffix("ies") { return String(str.dropLast(3)) + "y" }
    if str.hasSuffix("ses") { return String(str.dropLast(2)) }
    if str.hasSuffix("s") { return String(str.dropLast(1)) }
    return str
}

/// Singularizes a snake_case string by singularizing only the last segment.
func singularizeSnakeCase(_ str: String) -> String {
    guard let lastUnderscore = str.lastIndex(of: "_") else {
        return singularize(str)
    }
    let prefix = str[str.startIndex...lastUnderscore]
    let suffix = singularize(String(str[str.index(after: lastUnderscore)...]))
    return prefix + suffix
}

/// Converts PascalCase to kebab-case.
func toKebabCase(_ str: String) -> String {
    var result = ""
    for (i, ch) in str.enumerated() {
        if ch.isUppercase {
            if i > 0 {
                result.append("-")
            }
            result.append(ch.lowercased())
        } else {
            result.append(ch)
        }
    }
    return result
}

/// Converts a snake_case or camelCase name to a human-readable description.
func toHumanReadable(_ str: String) -> String {
    if str.hasSuffix("Id") {
        let base = String(str.dropLast(2))
        let spaced = base.replacingOccurrences(
            of: "([a-z])([A-Z])", with: "$1 $2",
            options: .regularExpression
        ).lowercased()
        return spaced + " ID"
    }
    return str
        .replacingOccurrences(of: "_", with: " ")
        .replacingOccurrences(
            of: "([a-z])([A-Z])", with: "$1 $2",
            options: .regularExpression
        )
        .lowercased()
}

/// Resolves a $ref string to the schema name (last path component).
func resolveRef(_ ref: String) -> String {
    ref.split(separator: "/").last.map(String.init) ?? ""
}

/// Strips prefix path components that are not part of the API path.
func convertPath(_ path: String) -> String {
    path
}

/// Extracts the resource type from an operationId using verb patterns.
func extractResourceType(_ operationId: String) -> String {
    for (prefix, _) in verbPatterns {
        if operationId.hasPrefix(prefix) {
            let remainder = String(operationId.dropFirst(prefix.count))
            if remainder.isEmpty { return "resource" }
            var snakeCase = ""
            for (i, ch) in remainder.enumerated() {
                if ch.isUppercase && i > 0 {
                    snakeCase.append("_")
                }
                snakeCase.append(ch.lowercased())
            }
            return singularizeSnakeCase(snakeCase)
        }
    }
    return "resource"
}

/// Converts an OpenAPI path to a Swift string interpolation.
///
/// `/boards/{boardId}/cards/{cardId}.json`
/// -> `"/boards/\(boardId)/cards/\(cardId).json"`
func pathToSwiftInterpolation(_ path: String) -> String {
    let stripped = convertPath(path)
    var result = stripped
    let regex = try! NSRegularExpression(pattern: "\\{([^}]+)\\}")
    let matches = regex.matches(in: stripped, range: NSRange(stripped.startIndex..., in: stripped))
    for match in matches.reversed() {
        let range = Range(match.range, in: stripped)!
        let paramRange = Range(match.range(at: 1), in: stripped)!
        let paramName = toCamelCase(String(stripped[paramRange]))
        result.replaceSubrange(range, with: "\\(\(paramName))")
    }
    return result
}
