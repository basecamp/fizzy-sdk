// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct CardRef: Codable, Sendable {
    public let id: Int
    public let url: String

    public init(id: Int, url: String) {
        self.id = id
        self.url = url
    }
}
