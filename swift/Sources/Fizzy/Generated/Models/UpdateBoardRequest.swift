// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct UpdateBoardRequest: Codable, Sendable {
    public var allAccess: Bool?
    public var autoPostponePeriod: Int32?
    public var name: String?

    public init(allAccess: Bool? = nil, autoPostponePeriod: Int32? = nil, name: String? = nil) {
        self.allAccess = allAccess
        self.autoPostponePeriod = autoPostponePeriod
        self.name = name
    }
}
