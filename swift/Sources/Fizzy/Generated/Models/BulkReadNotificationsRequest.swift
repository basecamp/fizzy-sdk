// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct BulkReadNotificationsRequest: Codable, Sendable {
    public var notificationIds: [String]?

    public init(notificationIds: [String]? = nil) {
        self.notificationIds = notificationIds
    }
}
