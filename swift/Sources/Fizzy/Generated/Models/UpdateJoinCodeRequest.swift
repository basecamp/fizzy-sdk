// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct UpdateJoinCodeRequest: Codable, Sendable {
    public var usageLimit: Int32?

    public init(usageLimit: Int32? = nil) {
        self.usageLimit = usageLimit
    }
}
