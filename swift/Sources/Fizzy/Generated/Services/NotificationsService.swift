// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct TrayNotificationOptions: Sendable {
    public var includeRead: Bool?

    public init(includeRead: Bool? = nil) {
        self.includeRead = includeRead
    }
}

public struct ListNotificationOptions: Sendable {
    public var read: Bool?
    public var maxItems: Int?

    public init(read: Bool? = nil, maxItems: Int? = nil) {
        self.read = read
        self.maxItems = maxItems
    }
}


public final class NotificationsService: BaseService, @unchecked Sendable {
    public func bulkRead(accountId: String, req: BulkReadNotificationsRequest) async throws {
        try await requestVoid(
            OperationInfo(service: "Notifications", operation: "BulkReadNotifications", resourceType: "read_notification", isMutation: true),
            method: "POST",
            path: "/\(accountId)/notifications/bulk_reading.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "BulkReadNotifications")
        )
    }

    public func tray(accountId: String, options: TrayNotificationOptions? = nil) async throws -> [Notification] {
        var queryItems: [URLQueryItem] = []
        if let includeRead = options?.includeRead {
            queryItems.append(URLQueryItem(name: "include_read", value: String(includeRead)))
        }
        return try await request(
            OperationInfo(service: "Notifications", operation: "GetNotificationTray", resourceType: "notification_tray", isMutation: false),
            method: "GET",
            path: "/\(accountId)/notifications/tray.json" + queryString(queryItems),
            retryConfig: Metadata.retryConfig(for: "GetNotificationTray")
        )
    }

    public func list(accountId: String, options: ListNotificationOptions? = nil) async throws -> ListResult<Notification> {
        var queryItems: [URLQueryItem] = []
        if let read = options?.read {
            queryItems.append(URLQueryItem(name: "read", value: String(read)))
        }
        return try await requestPaginated(
            OperationInfo(service: "Notifications", operation: "ListNotifications", resourceType: "notification", isMutation: false),
            path: "/\(accountId)/notifications.json",
            queryItems: queryItems.isEmpty ? nil : queryItems,
            paginationOpts: options.flatMap { PaginationOptions(maxItems: $0.maxItems) },
            retryConfig: Metadata.retryConfig(for: "ListNotifications")
        )
    }

    public func read(accountId: String, notificationId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Notifications", operation: "ReadNotification", resourceType: "notification", isMutation: true),
            method: "POST",
            path: "/\(accountId)/notifications/\(notificationId)/reading.json",
            retryConfig: Metadata.retryConfig(for: "ReadNotification")
        )
    }

    public func unread(accountId: String, notificationId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Notifications", operation: "UnreadNotification", resourceType: "notification", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/notifications/\(notificationId)/reading.json",
            retryConfig: Metadata.retryConfig(for: "UnreadNotification")
        )
    }
}
