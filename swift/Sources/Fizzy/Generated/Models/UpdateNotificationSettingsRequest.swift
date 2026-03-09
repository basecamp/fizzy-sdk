// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct UpdateNotificationSettingsRequest: Codable, Sendable {
    public var bundleEmailFrequency: String?

    public init(bundleEmailFrequency: String? = nil) {
        self.bundleEmailFrequency = bundleEmailFrequency
    }
}
