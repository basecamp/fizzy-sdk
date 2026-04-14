// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct JoinCode: Codable, Sendable {
    public let code: String
    public let url: String
    public var active: Bool?
    public var usageCount: Int32?
    public var usageLimit: Int32?

    public init(
        code: String,
        url: String,
        active: Bool? = nil,
        usageCount: Int32? = nil,
        usageLimit: Int32? = nil
    ) {
        self.code = code
        self.url = url
        self.active = active
        self.usageCount = usageCount
        self.usageLimit = usageLimit
    }
}
