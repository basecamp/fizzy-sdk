// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Reaction: Codable, Sendable {
    public let content: String
    public let id: String
    public let reacter: UserSummary
    public let url: String

    public init(
        content: String,
        id: String,
        reacter: UserSummary,
        url: String
    ) {
        self.content = content
        self.id = id
        self.reacter = reacter
        self.url = url
    }
}
