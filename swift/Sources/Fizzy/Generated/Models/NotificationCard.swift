// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct NotificationCard: Codable, Sendable {
    public let closed: Bool
    public let id: String
    public let number: Int32
    public let postponed: Bool
    public let status: String
    public let title: String
    public let url: String
    public var boardName: String?
    public var column: Column?

    public init(
        closed: Bool,
        id: String,
        number: Int32,
        postponed: Bool,
        status: String,
        title: String,
        url: String,
        boardName: String? = nil,
        column: Column? = nil
    ) {
        self.closed = closed
        self.id = id
        self.number = number
        self.postponed = postponed
        self.status = status
        self.title = title
        self.url = url
        self.boardName = boardName
        self.column = column
    }
}
