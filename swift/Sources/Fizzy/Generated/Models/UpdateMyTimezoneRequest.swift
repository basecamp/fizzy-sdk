// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct UpdateMyTimezoneRequest: Codable, Sendable {
    public let timezoneName: String

    public init(timezoneName: String) {
        self.timezoneName = timezoneName
    }
}
