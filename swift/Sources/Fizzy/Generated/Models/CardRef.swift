// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct CardRef: Codable, Sendable {
    public let id: String
    public let url: String

    public init(id: String, url: String) {
        self.id = id
        self.url = url
    }
}
