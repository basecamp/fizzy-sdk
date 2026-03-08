// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct CreateBoardRequest: Codable, Sendable {
    public var allAccess: Bool?
    public var autoPostponePeriod: Int32?
    public let name: String
    public var publicDescription: String?

    public init(
        allAccess: Bool? = nil,
        autoPostponePeriod: Int32? = nil,
        name: String,
        publicDescription: String? = nil
    ) {
        self.allAccess = allAccess
        self.autoPostponePeriod = autoPostponePeriod
        self.name = name
        self.publicDescription = publicDescription
    }
}
