// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct UpdateBoardRequest: Codable, Sendable {
    public var allAccess: Bool?
    public var name: String?

    public init(allAccess: Bool? = nil, name: String? = nil) {
        self.allAccess = allAccess
        self.name = name
    }
}
