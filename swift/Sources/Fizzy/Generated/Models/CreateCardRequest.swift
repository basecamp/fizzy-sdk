// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct CreateCardRequest: Codable, Sendable {
    public var assigneeIds: [String]?
    public var boardId: String?
    public var columnId: String?
    public var createdAt: String?
    public var description: String?
    public var image: String?
    public var lastActiveAt: String?
    public var tagNames: [String]?
    public let title: String

    public init(
        assigneeIds: [String]? = nil,
        boardId: String? = nil,
        columnId: String? = nil,
        createdAt: String? = nil,
        description: String? = nil,
        image: String? = nil,
        lastActiveAt: String? = nil,
        tagNames: [String]? = nil,
        title: String
    ) {
        self.assigneeIds = assigneeIds
        self.boardId = boardId
        self.columnId = columnId
        self.createdAt = createdAt
        self.description = description
        self.image = image
        self.lastActiveAt = lastActiveAt
        self.tagNames = tagNames
        self.title = title
    }
}
