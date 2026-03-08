// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Tag: Codable, Sendable {
    public let createdAt: String
    public let id: String
    public let title: String
    public var url: String?

    public init(
        createdAt: String,
        id: String,
        title: String,
        url: String? = nil
    ) {
        self.createdAt = createdAt
        self.id = id
        self.title = title
        self.url = url
    }
}
