// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct JoinCode: Codable, Sendable {
    public let code: String
    public let url: String
    public var usageLimit: Int32?

    public init(code: String, url: String, usageLimit: Int32? = nil) {
        self.code = code
        self.url = url
        self.usageLimit = usageLimit
    }
}
