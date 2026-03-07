// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct User: Codable, Sendable {
    public let active: Bool
    public let createdAt: String
    public let emailAddress: String
    public let id: String
    public let name: String
    public let role: String
    public let url: String
    public var avatarUrl: String?

    public init(
        active: Bool,
        createdAt: String,
        emailAddress: String,
        id: String,
        name: String,
        role: String,
        url: String,
        avatarUrl: String? = nil
    ) {
        self.active = active
        self.createdAt = createdAt
        self.emailAddress = emailAddress
        self.id = id
        self.name = name
        self.role = role
        self.url = url
        self.avatarUrl = avatarUrl
    }
}
