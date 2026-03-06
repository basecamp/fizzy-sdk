// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct MoveCardRequest: Codable, Sendable {
    public let boardId: Int
    public var columnId: Int?

    public init(boardId: Int, columnId: Int? = nil) {
        self.boardId = boardId
        self.columnId = columnId
    }
}
