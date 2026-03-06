// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Pin: Codable, Sendable {
    public let card: CardRef
    public let createdAt: String
    public let id: Int

    public init(card: CardRef, createdAt: String, id: Int) {
        self.card = card
        self.createdAt = createdAt
        self.id = id
    }
}
