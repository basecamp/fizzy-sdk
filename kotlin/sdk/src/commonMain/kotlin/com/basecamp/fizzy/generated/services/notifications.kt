package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.models.*
import com.basecamp.fizzy.services.BaseService
import kotlinx.serialization.json.JsonElement

/**
 * Service for Notifications operations.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
class NotificationsService(client: AccountClient) : BaseService(client) {

    /**
     * Lists the caller's notifications. It takes no read/unread filter: the first page holds up to 100 unread notifications followed by a page of read ones, and later pages hold read ones only.
     * @param options Optional query parameters and pagination control
     */
    suspend fun list(options: PaginationOptions? = null): ListResult<Notification> {
        val info = OperationInfo(
            service = "Notifications",
            operation = "ListNotifications",
            resourceType = "notification",
            isMutation = false,
            boardId = null,
            resourceId = null,
        )
        return requestPaginated(info, options, {
            httpGet("/notifications.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<List<Notification>>(body)
        }
    }

    /**
     * Marks every unread notification of the caller read. It takes no selection.
     * @param body Request body
     */
    suspend fun bulkRead(body: BulkReadNotificationsBody): Unit {
        val info = OperationInfo(
            service = "Notifications",
            operation = "BulkReadNotifications",
            resourceType = "read_notification",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        request(info, {
            httpPost("/notifications/bulk_reading.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                body.notificationIds?.let { put("notification_ids", kotlinx.serialization.json.JsonArray(it.map { kotlinx.serialization.json.JsonPrimitive(it) })) }
            }), operationName = info.operation)
        }) { Unit }
    }

    /**
     * tray operation
     * @param options Optional query parameters and pagination control
     */
    suspend fun tray(options: GetNotificationTrayOptions? = null): List<Notification> {
        val info = OperationInfo(
            service = "Notifications",
            operation = "GetNotificationTray",
            resourceType = "notification_tray",
            isMutation = false,
            boardId = null,
            resourceId = null,
        )
        val qs = buildQueryString(
            "include_read" to options?.includeRead,
        )
        return request(info, {
            httpGet("/notifications/tray.json" + qs, operationName = info.operation)
        }) { body ->
            json.decodeFromString<List<Notification>>(body)
        }
    }

    /**
     * read operation
     * @param notificationId The notification ID
     */
    suspend fun read(notificationId: String): Unit {
        val info = OperationInfo(
            service = "Notifications",
            operation = "ReadNotification",
            resourceType = "notification",
            isMutation = true,
            boardId = null,
            resourceId = notificationId,
        )
        request(info, {
            httpPost("/notifications/${notificationId}/reading.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * unread operation
     * @param notificationId The notification ID
     */
    suspend fun unread(notificationId: String): Unit {
        val info = OperationInfo(
            service = "Notifications",
            operation = "UnreadNotification",
            resourceType = "notification",
            isMutation = true,
            boardId = null,
            resourceId = notificationId,
        )
        request(info, {
            httpDelete("/notifications/${notificationId}/reading.json", operationName = info.operation)
        }) { Unit }
    }
}
