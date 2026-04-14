// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Activity: Codable, Sendable {
    public let action: String
    public let board: Board
    public let createdAt: String
    public let creator: User
    public let description: String
    public let eventable: ActivityEventable
    public let eventableType: String
    public let id: String
    public let particulars: ActivityParticulars
    public let url: String

    public init(
        action: String,
        board: Board,
        createdAt: String,
        creator: User,
        description: String,
        eventable: ActivityEventable,
        eventableType: String,
        id: String,
        particulars: ActivityParticulars,
        url: String
    ) {
        self.action = action
        self.board = board
        self.createdAt = createdAt
        self.creator = creator
        self.description = description
        self.eventable = eventable
        self.eventableType = eventableType
        self.id = id
        self.particulars = particulars
        self.url = url
    }
}
