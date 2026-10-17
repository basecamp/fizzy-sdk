// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct UpdateCardRequest: Codable, Sendable {
    public var createdAt: String?
    public var description: String?
    public var image: String?
    public var title: String?

    public init(
        createdAt: String? = nil,
        description: String? = nil,
        image: String? = nil,
        title: String? = nil
    ) {
        self.createdAt = createdAt
        self.description = description
        self.image = image
        self.title = title
    }
}
