// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct BoardAccesses: Codable, Sendable {
    public let allAccess: Bool
    public let boardId: String
    public let users: [BoardAccessUser]

    public init(allAccess: Bool, boardId: String, users: [BoardAccessUser]) {
        self.allAccess = allAccess
        self.boardId = boardId
        self.users = users
    }
}
