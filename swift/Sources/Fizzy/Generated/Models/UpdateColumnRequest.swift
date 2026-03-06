// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct UpdateColumnRequest: Codable, Sendable {
    public var color: String?
    public var name: String?

    public init(color: String? = nil, name: String? = nil) {
        self.color = color
        self.name = name
    }
}
