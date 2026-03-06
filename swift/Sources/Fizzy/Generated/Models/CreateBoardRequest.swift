// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct CreateBoardRequest: Codable, Sendable {
    public var allAccess: Bool?
    public let name: String

    public init(allAccess: Bool? = nil, name: String) {
        self.allAccess = allAccess
        self.name = name
    }
}
