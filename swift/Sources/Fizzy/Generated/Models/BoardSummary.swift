// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct BoardSummary: Codable, Sendable {
    public let id: String
    public let name: String
    public let url: String

    public init(id: String, name: String, url: String) {
        self.id = id
        self.name = name
        self.url = url
    }
}
