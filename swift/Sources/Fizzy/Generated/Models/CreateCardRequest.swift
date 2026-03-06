// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct CreateCardRequest: Codable, Sendable {
    public var assigneeIds: [Int]?
    public var boardId: Int?
    public var columnId: Int?
    public var description: String?
    public var tagNames: [String]?
    public let title: String

    public init(
        assigneeIds: [Int]? = nil,
        boardId: Int? = nil,
        columnId: Int? = nil,
        description: String? = nil,
        tagNames: [String]? = nil,
        title: String
    ) {
        self.assigneeIds = assigneeIds
        self.boardId = boardId
        self.columnId = columnId
        self.description = description
        self.tagNames = tagNames
        self.title = title
    }
}
