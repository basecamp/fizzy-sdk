// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct CreateAccessTokenRequest: Codable, Sendable {
    public let description: String
    public let permission: String

    public init(description: String, permission: String) {
        self.description = description
        self.permission = permission
    }
}
