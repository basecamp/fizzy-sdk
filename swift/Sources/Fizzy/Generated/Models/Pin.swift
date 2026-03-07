// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Pin: Codable, Sendable {
    public let card: CardRef
    public let createdAt: String
    public let id: String

    public init(card: CardRef, createdAt: String, id: String) {
        self.card = card
        self.createdAt = createdAt
        self.id = id
    }
}
