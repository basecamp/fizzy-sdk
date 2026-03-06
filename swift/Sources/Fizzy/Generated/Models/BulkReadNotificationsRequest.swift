// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct BulkReadNotificationsRequest: Codable, Sendable {
    public var notificationIds: [Int]?

    public init(notificationIds: [Int]? = nil) {
        self.notificationIds = notificationIds
    }
}
