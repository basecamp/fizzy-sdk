// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct RegisterDeviceRequest: Codable, Sendable {
    public var name: String?
    public let platform: String
    public let token: String

    public init(name: String? = nil, platform: String, token: String) {
        self.name = name
        self.platform = platform
        self.token = token
    }
}
