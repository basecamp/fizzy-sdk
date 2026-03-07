// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct UserSummary: Codable, Sendable {
    public let id: String
    public let name: String
    public var avatarUrl: String?

    public init(id: String, name: String, avatarUrl: String? = nil) {
        self.id = id
        self.name = name
        self.avatarUrl = avatarUrl
    }
}
