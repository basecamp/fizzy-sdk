package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.models.*
import com.basecamp.fizzy.services.BaseService
import kotlinx.serialization.json.JsonElement

/**
 * Service for Reactions operations.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
class ReactionsService(client: AccountClient) : BaseService(client) {

    /**
     * listForComment operation
     * @param cardNumber The card number
     * @param commentId The comment ID
     */
    suspend fun listForComment(cardNumber: Long, commentId: String): List<Reaction> {
        val info = OperationInfo(
            service = "Reactions",
            operation = "ListCommentReactions",
            resourceType = "comment_reaction",
            isMutation = false,
            boardId = null,
            resourceId = cardNumber,
        )
        return request(info, {
            httpGet("/cards/${cardNumber}/comments/${commentId}/reactions.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<List<Reaction>>(body)
        }
    }

    /**
     * createForComment operation
     * @param cardNumber The card number
     * @param commentId The comment ID
     * @param body Request body
     */
    suspend fun createForComment(cardNumber: Long, commentId: String, body: CreateCommentReactionBody): Reaction {
        val info = OperationInfo(
            service = "Reactions",
            operation = "CreateCommentReaction",
            resourceType = "comment_reaction",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        return request(info, {
            httpPost("/cards/${cardNumber}/comments/${commentId}/reactions.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("content", kotlinx.serialization.json.JsonPrimitive(body.content))
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<Reaction>(body)
        }
    }

    /**
     * deleteForComment operation
     * @param cardNumber The card number
     * @param commentId The comment ID
     * @param reactionId The reaction ID
     */
    suspend fun deleteForComment(cardNumber: Long, commentId: String, reactionId: String): Unit {
        val info = OperationInfo(
            service = "Reactions",
            operation = "DeleteCommentReaction",
            resourceType = "comment_reaction",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpDelete("/cards/${cardNumber}/comments/${commentId}/reactions/${reactionId}", operationName = info.operation)
        }) { Unit }
    }

    /**
     * listForCard operation
     * @param cardNumber The card number
     */
    suspend fun listForCard(cardNumber: Long): List<Reaction> {
        val info = OperationInfo(
            service = "Reactions",
            operation = "ListCardReactions",
            resourceType = "card_reaction",
            isMutation = false,
            boardId = null,
            resourceId = cardNumber,
        )
        return request(info, {
            httpGet("/cards/${cardNumber}/reactions.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<List<Reaction>>(body)
        }
    }

    /**
     * createForCard operation
     * @param cardNumber The card number
     * @param body Request body
     */
    suspend fun createForCard(cardNumber: Long, body: CreateCardReactionBody): Reaction {
        val info = OperationInfo(
            service = "Reactions",
            operation = "CreateCardReaction",
            resourceType = "card_reaction",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        return request(info, {
            httpPost("/cards/${cardNumber}/reactions.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("content", kotlinx.serialization.json.JsonPrimitive(body.content))
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<Reaction>(body)
        }
    }

    /**
     * deleteForCard operation
     * @param cardNumber The card number
     * @param reactionId The reaction ID
     */
    suspend fun deleteForCard(cardNumber: Long, reactionId: String): Unit {
        val info = OperationInfo(
            service = "Reactions",
            operation = "DeleteCardReaction",
            resourceType = "card_reaction",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpDelete("/cards/${cardNumber}/reactions/${reactionId}", operationName = info.operation)
        }) { Unit }
    }
}
