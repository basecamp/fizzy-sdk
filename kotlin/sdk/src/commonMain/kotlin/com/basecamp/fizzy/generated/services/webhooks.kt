package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.models.*
import com.basecamp.fizzy.services.BaseService
import kotlinx.serialization.json.JsonElement

/**
 * Service for Webhooks operations.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
class WebhooksService(client: AccountClient) : BaseService(client) {

    /**
     * list operation
     * @param boardId The board ID
     */
    suspend fun list(boardId: String): List<Webhook> {
        val info = OperationInfo(
            service = "Webhooks",
            operation = "ListWebhooks",
            resourceType = "webhook",
            isMutation = false,
            boardId = boardId,
            resourceId = null,
        )
        return request(info, {
            httpGet("/boards/${boardId}/webhooks.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<List<Webhook>>(body)
        }
    }

    /**
     * create operation
     * @param boardId The board ID
     * @param body Request body
     */
    suspend fun create(boardId: String, body: CreateWebhookBody): Webhook {
        val info = OperationInfo(
            service = "Webhooks",
            operation = "CreateWebhook",
            resourceType = "webhook",
            isMutation = true,
            boardId = boardId,
            resourceId = null,
        )
        return request(info, {
            httpPost("/boards/${boardId}/webhooks.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("name", kotlinx.serialization.json.JsonPrimitive(body.name))
                put("url", kotlinx.serialization.json.JsonPrimitive(body.url))
                body.subscribedActions?.let { put("subscribed_actions", kotlinx.serialization.json.JsonArray(it.map { kotlinx.serialization.json.JsonPrimitive(it) })) }
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<Webhook>(body)
        }
    }

    /**
     * get operation
     * @param boardId The board ID
     * @param webhookId The webhook ID
     */
    suspend fun get(boardId: String, webhookId: String): Webhook {
        val info = OperationInfo(
            service = "Webhooks",
            operation = "GetWebhook",
            resourceType = "webhook",
            isMutation = false,
            boardId = boardId,
            resourceId = webhookId,
        )
        return request(info, {
            httpGet("/boards/${boardId}/webhooks/${webhookId}", operationName = info.operation)
        }) { body ->
            json.decodeFromString<Webhook>(body)
        }
    }

    /**
     * update operation
     * @param boardId The board ID
     * @param webhookId The webhook ID
     * @param body Request body
     */
    suspend fun update(boardId: String, webhookId: String, body: UpdateWebhookBody): Webhook {
        val info = OperationInfo(
            service = "Webhooks",
            operation = "UpdateWebhook",
            resourceType = "webhook",
            isMutation = true,
            boardId = boardId,
            resourceId = webhookId,
        )
        return request(info, {
            httpPatch("/boards/${boardId}/webhooks/${webhookId}", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                body.name?.let { put("name", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.url?.let { put("url", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.subscribedActions?.let { put("subscribed_actions", kotlinx.serialization.json.JsonArray(it.map { kotlinx.serialization.json.JsonPrimitive(it) })) }
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<Webhook>(body)
        }
    }

    /**
     * delete operation
     * @param boardId The board ID
     * @param webhookId The webhook ID
     */
    suspend fun delete(boardId: String, webhookId: String): Unit {
        val info = OperationInfo(
            service = "Webhooks",
            operation = "DeleteWebhook",
            resourceType = "webhook",
            isMutation = true,
            boardId = boardId,
            resourceId = webhookId,
        )
        request(info, {
            httpDelete("/boards/${boardId}/webhooks/${webhookId}", operationName = info.operation)
        }) { Unit }
    }

    /**
     * activate operation
     * @param boardId The board ID
     * @param webhookId The webhook ID
     */
    suspend fun activate(boardId: String, webhookId: String): Unit {
        val info = OperationInfo(
            service = "Webhooks",
            operation = "ActivateWebhook",
            resourceType = "webhook",
            isMutation = true,
            boardId = boardId,
            resourceId = webhookId,
        )
        request(info, {
            httpPost("/boards/${boardId}/webhooks/${webhookId}/activation.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * listWebhookDeliveries operation
     * @param boardId The board ID
     * @param webhookId The webhook ID
     * @param options Optional query parameters and pagination control
     */
    suspend fun listWebhookDeliveries(boardId: String, webhookId: String, options: PaginationOptions? = null): ListResult<WebhookDelivery> {
        val info = OperationInfo(
            service = "Webhooks",
            operation = "ListWebhookDeliveries",
            resourceType = "webhook_delivery",
            isMutation = false,
            boardId = boardId,
            resourceId = webhookId,
        )
        return requestPaginated(info, options, {
            httpGet("/boards/${boardId}/webhooks/${webhookId}/deliveries.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<List<WebhookDelivery>>(body)
        }
    }
}
