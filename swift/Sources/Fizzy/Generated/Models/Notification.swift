// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Notification: Codable, Sendable {
    public let createdAt: String
    public let creator: User
    public let id: String
    public let read: Bool
    public let sourceType: String
    public let unreadCount: Int32
    public let url: String
    public var body: String?
    public var card: NotificationCard?
    public var readAt: String?
    public var title: String?

    public init(
        createdAt: String,
        creator: User,
        id: String,
        read: Bool,
        sourceType: String,
        unreadCount: Int32,
        url: String,
        body: String? = nil,
        card: NotificationCard? = nil,
        readAt: String? = nil,
        title: String? = nil
    ) {
        self.createdAt = createdAt
        self.creator = creator
        self.id = id
        self.read = read
        self.sourceType = sourceType
        self.unreadCount = unreadCount
        self.url = url
        self.body = body
        self.card = card
        self.readAt = readAt
        self.title = title
    }
}
