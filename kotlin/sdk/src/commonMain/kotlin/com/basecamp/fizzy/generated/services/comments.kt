package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.models.*
import com.basecamp.fizzy.services.BaseService
import kotlinx.serialization.json.JsonElement

/**
 * Service for Comments operations.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
class CommentsService(client: AccountClient) : BaseService(client) {

    /**
     * list operation
     * @param cardNumber The card number
     * @param options Optional query parameters and pagination control
     */
    suspend fun list(cardNumber: Long, options: PaginationOptions? = null): ListResult<Comment> {
        val info = OperationInfo(
            service = "Comments",
            operation = "ListComments",
            resourceType = "comment",
            isMutation = false,
            boardId = null,
            resourceId = cardNumber,
        )
        return requestPaginated(info, options, {
            httpGet("/cards/${cardNumber}/comments.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<List<Comment>>(body)
        }
    }

    /**
     * create operation
     * @param cardNumber The card number
     * @param body Request body
     */
    suspend fun create(cardNumber: Long, body: CreateCommentBody): Comment {
        val info = OperationInfo(
            service = "Comments",
            operation = "CreateComment",
            resourceType = "comment",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        return request(info, {
            httpPost("/cards/${cardNumber}/comments.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("body", kotlinx.serialization.json.JsonPrimitive(body.body))
                body.createdAt?.let { put("created_at", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<Comment>(body)
        }
    }

    /**
     * get operation
     * @param cardNumber The card number
     * @param commentId The comment ID
     */
    suspend fun get(cardNumber: Long, commentId: String): Comment {
        val info = OperationInfo(
            service = "Comments",
            operation = "GetComment",
            resourceType = "comment",
            isMutation = false,
            boardId = null,
            resourceId = cardNumber,
        )
        return request(info, {
            httpGet("/cards/${cardNumber}/comments/${commentId}", operationName = info.operation)
        }) { body ->
            json.decodeFromString<Comment>(body)
        }
    }

    /**
     * update operation
     * @param cardNumber The card number
     * @param commentId The comment ID
     * @param body Request body
     */
    suspend fun update(cardNumber: Long, commentId: String, body: UpdateCommentBody): Comment {
        val info = OperationInfo(
            service = "Comments",
            operation = "UpdateComment",
            resourceType = "comment",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        return request(info, {
            httpPatch("/cards/${cardNumber}/comments/${commentId}", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("body", kotlinx.serialization.json.JsonPrimitive(body.body))
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<Comment>(body)
        }
    }

    /**
     * delete operation
     * @param cardNumber The card number
     * @param commentId The comment ID
     */
    suspend fun delete(cardNumber: Long, commentId: String): Unit {
        val info = OperationInfo(
            service = "Comments",
            operation = "DeleteComment",
            resourceType = "comment",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpDelete("/cards/${cardNumber}/comments/${commentId}", operationName = info.operation)
        }) { Unit }
    }
}
