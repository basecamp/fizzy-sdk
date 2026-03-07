// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Comment: Codable, Sendable {
    public let body: RichTextBody
    public let createdAt: String
    public let creator: UserSummary
    public let id: String
    public let updatedAt: String
    public let url: String
    public var card: CardRef?
    public var reactionsUrl: String?

    public init(
        body: RichTextBody,
        createdAt: String,
        creator: UserSummary,
        id: String,
        updatedAt: String,
        url: String,
        card: CardRef? = nil,
        reactionsUrl: String? = nil
    ) {
        self.body = body
        self.createdAt = createdAt
        self.creator = creator
        self.id = id
        self.updatedAt = updatedAt
        self.url = url
        self.card = card
        self.reactionsUrl = reactionsUrl
    }
}
