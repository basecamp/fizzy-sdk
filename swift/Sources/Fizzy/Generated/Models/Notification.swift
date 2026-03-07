// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Notification: Codable, Sendable {
    public let createdAt: String
    public let creator: UserSummary
    public let id: String
    public let read: Bool
    public let sourceType: String
    public let unreadCount: Int32
    public let url: String
    public var card: NotificationCard?
    public var readAt: String?

    public init(
        createdAt: String,
        creator: UserSummary,
        id: String,
        read: Bool,
        sourceType: String,
        unreadCount: Int32,
        url: String,
        card: NotificationCard? = nil,
        readAt: String? = nil
    ) {
        self.createdAt = createdAt
        self.creator = creator
        self.id = id
        self.read = read
        self.sourceType = sourceType
        self.unreadCount = unreadCount
        self.url = url
        self.card = card
        self.readAt = readAt
    }
}
