// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct MoveCardRequest: Codable, Sendable {
    public let boardId: String
    public var columnId: String?

    public init(boardId: String, columnId: String? = nil) {
        self.boardId = boardId
        self.columnId = columnId
    }
}
