// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Column: Codable, Sendable {
    public let createdAt: String
    public let id: String
    public let name: String
    public var cardsUrl: String?
    public var color: String?

    public init(
        createdAt: String,
        id: String,
        name: String,
        cardsUrl: String? = nil,
        color: String? = nil
    ) {
        self.createdAt = createdAt
        self.id = id
        self.name = name
        self.cardsUrl = cardsUrl
        self.color = color
    }
}
