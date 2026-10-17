// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct CreateCardRequest: Codable, Sendable {
    public let boardId: String
    public var createdAt: String?
    public var description: String?
    public var image: String?
    public var lastActiveAt: String?
    public let title: String

    public init(
        boardId: String,
        createdAt: String? = nil,
        description: String? = nil,
        image: String? = nil,
        lastActiveAt: String? = nil,
        title: String
    ) {
        self.boardId = boardId
        self.createdAt = createdAt
        self.description = description
        self.image = image
        self.lastActiveAt = lastActiveAt
        self.title = title
    }
}
