package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.models.*
import com.basecamp.fizzy.services.BaseService
import kotlinx.serialization.json.JsonElement

/**
 * Service for Steps operations.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
class StepsService(client: AccountClient) : BaseService(client) {

    /**
     * create operation
     * @param cardNumber The card number
     * @param body Request body
     */
    suspend fun create(cardNumber: Long, body: CreateStepBody): Step {
        val info = OperationInfo(
            service = "Steps",
            operation = "CreateStep",
            resourceType = "step",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        return request(info, {
            httpPost("/cards/${cardNumber}/steps.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("content", kotlinx.serialization.json.JsonPrimitive(body.content))
                body.completed?.let { put("completed", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<Step>(body)
        }
    }

    /**
     * get operation
     * @param cardNumber The card number
     * @param stepId The step ID
     */
    suspend fun get(cardNumber: Long, stepId: String): Step {
        val info = OperationInfo(
            service = "Steps",
            operation = "GetStep",
            resourceType = "step",
            isMutation = false,
            boardId = null,
            resourceId = cardNumber,
        )
        return request(info, {
            httpGet("/cards/${cardNumber}/steps/${stepId}", operationName = info.operation)
        }) { body ->
            json.decodeFromString<Step>(body)
        }
    }

    /**
     * update operation
     * @param cardNumber The card number
     * @param stepId The step ID
     * @param body Request body
     */
    suspend fun update(cardNumber: Long, stepId: String, body: UpdateStepBody): Step {
        val info = OperationInfo(
            service = "Steps",
            operation = "UpdateStep",
            resourceType = "step",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        return request(info, {
            httpPatch("/cards/${cardNumber}/steps/${stepId}", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                body.content?.let { put("content", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.completed?.let { put("completed", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<Step>(body)
        }
    }

    /**
     * delete operation
     * @param cardNumber The card number
     * @param stepId The step ID
     */
    suspend fun delete(cardNumber: Long, stepId: String): Unit {
        val info = OperationInfo(
            service = "Steps",
            operation = "DeleteStep",
            resourceType = "step",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpDelete("/cards/${cardNumber}/steps/${stepId}", operationName = info.operation)
        }) { Unit }
    }
}
