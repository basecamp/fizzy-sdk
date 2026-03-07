// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct NotificationCard: Codable, Sendable {
    public let id: String
    public let number: Int32
    public let title: String
    public let url: String
    public var board: BoardSummary?

    public init(
        id: String,
        number: Int32,
        title: String,
        url: String,
        board: BoardSummary? = nil
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.url = url
        self.board = board
    }
}
