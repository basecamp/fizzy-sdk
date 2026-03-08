// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Account: Codable, Sendable {
    public let createdAt: String
    public let id: String
    public let name: String
    public let slug: String
    public let url: String
    public var user: User?

    public init(
        createdAt: String,
        id: String,
        name: String,
        slug: String,
        url: String,
        user: User? = nil
    ) {
        self.createdAt = createdAt
        self.id = id
        self.name = name
        self.slug = slug
        self.url = url
        self.user = user
    }
}
