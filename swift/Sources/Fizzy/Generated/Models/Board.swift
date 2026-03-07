// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Board: Codable, Sendable {
    public let allAccess: Bool
    public let createdAt: String
    public let id: String
    public let name: String
    public let url: String
    public var creator: UserSummary?

    public init(
        allAccess: Bool,
        createdAt: String,
        id: String,
        name: String,
        url: String,
        creator: UserSummary? = nil
    ) {
        self.allAccess = allAccess
        self.createdAt = createdAt
        self.id = id
        self.name = name
        self.url = url
        self.creator = creator
    }
}
