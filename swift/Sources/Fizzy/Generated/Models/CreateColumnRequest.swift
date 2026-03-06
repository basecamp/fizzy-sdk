// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct CreateColumnRequest: Codable, Sendable {
    public var color: String?
    public let name: String

    public init(color: String? = nil, name: String) {
        self.color = color
        self.name = name
    }
}
