package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.models.*
import com.basecamp.fizzy.services.BaseService
import kotlinx.serialization.json.JsonElement

/**
 * Service for Miscellaneous operations.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
class MiscellaneousService(client: AccountClient) : BaseService(client) {

    /**
     * listAccessTokens operation
     */
    suspend fun listAccessTokens(): JsonElement {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "ListAccessTokens",
            resourceType = "access_token",
            isMutation = false,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpGetRoot("/my/access_tokens.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<JsonElement>(body)
        }
    }

    /**
     * createAccessToken operation
     * @param body Request body
     */
    suspend fun createAccessToken(body: CreateAccessTokenBody): JsonElement {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "CreateAccessToken",
            resourceType = "access_token",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpPostRoot("/my/access_tokens.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("description", kotlinx.serialization.json.JsonPrimitive(body.description))
                put("permission", kotlinx.serialization.json.JsonPrimitive(body.permission))
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<JsonElement>(body)
        }
    }

    /**
     * deleteAccessToken operation
     * @param accessTokenId The access token ID
     */
    suspend fun deleteAccessToken(accessTokenId: String): Unit {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "DeleteAccessToken",
            resourceType = "access_token",
            isMutation = true,
            boardId = null,
            resourceId = accessTokenId,
        )
        request(info, {
            httpDeleteRoot("/my/access_tokens/${accessTokenId}", operationName = info.operation)
        }) { Unit }
    }

    /**
     * updateAccountEntropy operation
     * @param body Request body
     */
    suspend fun updateAccountEntropy(body: UpdateAccountEntropyBody): JsonElement {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "UpdateAccountEntropy",
            resourceType = "account_entropy",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpPut("/account/entropy.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                body.autoPostponePeriodInDays?.let { put("auto_postpone_period_in_days", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<JsonElement>(body)
        }
    }

    /**
     * createAccountExport operation
     */
    suspend fun createAccountExport(): JsonElement {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "CreateAccountExport",
            resourceType = "account_export",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpPost("/account/exports.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<JsonElement>(body)
        }
    }

    /**
     * accountExport operation
     * @param exportId The export ID
     */
    suspend fun accountExport(exportId: String): JsonElement {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "GetAccountExport",
            resourceType = "account_export",
            isMutation = false,
            boardId = null,
            resourceId = exportId,
        )
        return request(info, {
            httpGet("/account/exports/${exportId}", operationName = info.operation)
        }) { body ->
            json.decodeFromString<JsonElement>(body)
        }
    }

    /**
     * joinCode operation
     */
    suspend fun joinCode(): JsonElement {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "GetJoinCode",
            resourceType = "join_code",
            isMutation = false,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpGet("/account/join_code.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<JsonElement>(body)
        }
    }

    /**
     * updateJoinCode operation
     * @param body Request body
     */
    suspend fun updateJoinCode(body: UpdateJoinCodeBody): Unit {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "UpdateJoinCode",
            resourceType = "join_code",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        request(info, {
            httpPatch("/account/join_code.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                body.usageLimit?.let { put("usage_limit", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { Unit }
    }

    /**
     * resetJoinCode operation
     */
    suspend fun resetJoinCode(): Unit {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "ResetJoinCode",
            resourceType = "resource",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        request(info, {
            httpDelete("/account/join_code.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * accountSettings operation
     */
    suspend fun accountSettings(): JsonElement {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "GetAccountSettings",
            resourceType = "account_setting",
            isMutation = false,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpGet("/account/settings.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<JsonElement>(body)
        }
    }

    /**
     * updateAccountSettings operation
     * @param body Request body
     */
    suspend fun updateAccountSettings(body: UpdateAccountSettingsBody): Unit {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "UpdateAccountSettings",
            resourceType = "account_setting",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        request(info, {
            httpPatch("/account/settings.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                body.name?.let { put("name", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { Unit }
    }

    /**
     * updateBoardEntropy operation
     * @param boardId The board ID
     * @param body Request body
     */
    suspend fun updateBoardEntropy(boardId: String, body: UpdateBoardEntropyBody): Board {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "UpdateBoardEntropy",
            resourceType = "board_entropy",
            isMutation = true,
            boardId = boardId,
            resourceId = null,
        )
        return request(info, {
            httpPut("/boards/${boardId}/entropy.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                body.autoPostponePeriodInDays?.let { put("auto_postpone_period_in_days", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<Board>(body)
        }
    }

    /**
     * updateBoardInvolvement operation
     * @param boardId The board ID
     * @param body Request body
     */
    suspend fun updateBoardInvolvement(boardId: String, body: UpdateBoardInvolvementBody): Unit {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "UpdateBoardInvolvement",
            resourceType = "board_involvement",
            isMutation = true,
            boardId = boardId,
            resourceId = null,
        )
        request(info, {
            httpPatch("/boards/${boardId}/involvement.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                body.involvement?.let { put("involvement", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { Unit }
    }

    /**
     * markCardRead operation
     * @param cardNumber The card number
     */
    suspend fun markCardRead(cardNumber: Long): Unit {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "MarkCardRead",
            resourceType = "resource",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpPost("/cards/${cardNumber}/reading.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * markCardUnread operation
     * @param cardNumber The card number
     */
    suspend fun markCardUnread(cardNumber: Long): Unit {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "MarkCardUnread",
            resourceType = "resource",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpDelete("/cards/${cardNumber}/reading.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * moveColumnLeft operation
     * @param columnId The column ID
     */
    suspend fun moveColumnLeft(columnId: String): Unit {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "MoveColumnLeft",
            resourceType = "column_left",
            isMutation = true,
            boardId = null,
            resourceId = columnId,
        )
        request(info, {
            httpPost("/columns/${columnId}/left_position.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * moveColumnRight operation
     * @param columnId The column ID
     */
    suspend fun moveColumnRight(columnId: String): Unit {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "MoveColumnRight",
            resourceType = "column_right",
            isMutation = true,
            boardId = null,
            resourceId = columnId,
        )
        request(info, {
            httpPost("/columns/${columnId}/right_position.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * notificationSettings operation
     */
    suspend fun notificationSettings(): JsonElement {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "GetNotificationSettings",
            resourceType = "notification_setting",
            isMutation = false,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpGet("/notifications/settings.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<JsonElement>(body)
        }
    }

    /**
     * updateNotificationSettings operation
     * @param body Request body
     */
    suspend fun updateNotificationSettings(body: UpdateNotificationSettingsBody): Unit {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "UpdateNotificationSettings",
            resourceType = "notification_setting",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        request(info, {
            httpPatch("/notifications/settings.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                body.bundleEmailFrequency?.let { put("bundle_email_frequency", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { Unit }
    }

    /**
     * deleteUserAvatar operation
     * @param userId The user ID
     */
    suspend fun deleteUserAvatar(userId: String): Unit {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "DeleteUserAvatar",
            resourceType = "user_avatar",
            isMutation = true,
            boardId = null,
            resourceId = userId,
        )
        request(info, {
            httpDelete("/users/${userId}/avatar", operationName = info.operation)
        }) { Unit }
    }

    /**
     * createPushSubscription operation
     * @param userId The user ID
     * @param body Request body
     */
    suspend fun createPushSubscription(userId: String, body: CreatePushSubscriptionBody): Unit {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "CreatePushSubscription",
            resourceType = "push_subscription",
            isMutation = true,
            boardId = null,
            resourceId = userId,
        )
        request(info, {
            httpPost("/users/${userId}/push_subscriptions.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("endpoint", kotlinx.serialization.json.JsonPrimitive(body.endpoint))
                put("p256dh_key", kotlinx.serialization.json.JsonPrimitive(body.p256dhKey))
                put("auth_key", kotlinx.serialization.json.JsonPrimitive(body.authKey))
            }), operationName = info.operation)
        }) { Unit }
    }

    /**
     * deletePushSubscription operation
     * @param userId The user ID
     * @param pushSubscriptionId The push subscription ID
     */
    suspend fun deletePushSubscription(userId: String, pushSubscriptionId: String): Unit {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "DeletePushSubscription",
            resourceType = "push_subscription",
            isMutation = true,
            boardId = null,
            resourceId = userId,
        )
        request(info, {
            httpDelete("/users/${userId}/push_subscriptions/${pushSubscriptionId}", operationName = info.operation)
        }) { Unit }
    }

    /**
     * updateUserRole operation
     * @param userId The user ID
     * @param body Request body
     */
    suspend fun updateUserRole(userId: String, body: UpdateUserRoleBody): Unit {
        val info = OperationInfo(
            service = "Miscellaneous",
            operation = "UpdateUserRole",
            resourceType = "user_role",
            isMutation = true,
            boardId = null,
            resourceId = userId,
        )
        request(info, {
            httpPatch("/users/${userId}/role.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("role", kotlinx.serialization.json.JsonPrimitive(body.role))
            }), operationName = info.operation)
        }) { Unit }
    }
}
