// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct AccessToken: Codable, Sendable {
    public let createdAt: String
    public let description: String
    public let id: String
    public let permission: String
    public var token: String?

    public init(
        createdAt: String,
        description: String,
        id: String,
        permission: String,
        token: String? = nil
    ) {
        self.createdAt = createdAt
        self.description = description
        self.id = id
        self.permission = permission
        self.token = token
    }
}
