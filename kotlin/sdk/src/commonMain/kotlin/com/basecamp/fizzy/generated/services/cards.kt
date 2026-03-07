package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.models.*
import com.basecamp.fizzy.services.BaseService
import kotlinx.serialization.json.JsonElement

/**
 * Service for Cards operations.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
class CardsService(client: AccountClient) : BaseService(client) {

    /**
     * list operation
     * @param options Optional query parameters and pagination control
     */
    suspend fun list(options: ListCardsOptions? = null): ListResult<Card> {
        val info = OperationInfo(
            service = "Cards",
            operation = "ListCards",
            resourceType = "card",
            isMutation = false,
            boardId = null,
            resourceId = null,
        )
        val qs = buildQueryString(
            "board_id" to options?.boardId,
            "column_id" to options?.columnId,
            "assignee_id" to options?.assigneeId,
            "tag" to options?.tag,
            "status" to options?.status,
            "q" to options?.q,
        )
        return requestPaginated(info, options?.toPaginationOptions(), {
            httpGet("/cards.json" + qs, operationName = info.operation)
        }) { body ->
            json.decodeFromString<List<Card>>(body)
        }
    }

    /**
     * create operation
     * @param body Request body
     */
    suspend fun create(body: CreateCardBody): Card {
        val info = OperationInfo(
            service = "Cards",
            operation = "CreateCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpPost("/cards.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("title", kotlinx.serialization.json.JsonPrimitive(body.title))
                body.boardId?.let { put("board_id", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.columnId?.let { put("column_id", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.description?.let { put("description", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.assigneeIds?.let { put("assignee_ids", kotlinx.serialization.json.JsonArray(it.map { kotlinx.serialization.json.JsonPrimitive(it) })) }
                body.tagNames?.let { put("tag_names", kotlinx.serialization.json.JsonArray(it.map { kotlinx.serialization.json.JsonPrimitive(it) })) }
                body.image?.let { put("image", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.createdAt?.let { put("created_at", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.lastActiveAt?.let { put("last_active_at", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<Card>(body)
        }
    }

    /**
     * get operation
     * @param cardNumber The card number
     */
    suspend fun get(cardNumber: Long): Card {
        val info = OperationInfo(
            service = "Cards",
            operation = "GetCard",
            resourceType = "card",
            isMutation = false,
            boardId = null,
            resourceId = cardNumber,
        )
        return request(info, {
            httpGet("/cards/${cardNumber}", operationName = info.operation)
        }) { body ->
            json.decodeFromString<Card>(body)
        }
    }

    /**
     * update operation
     * @param cardNumber The card number
     * @param body Request body
     */
    suspend fun update(cardNumber: Long, body: UpdateCardBody): Card {
        val info = OperationInfo(
            service = "Cards",
            operation = "UpdateCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        return request(info, {
            httpPatch("/cards/${cardNumber}", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                body.title?.let { put("title", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.description?.let { put("description", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.columnId?.let { put("column_id", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.image?.let { put("image", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.createdAt?.let { put("created_at", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<Card>(body)
        }
    }

    /**
     * delete operation
     * @param cardNumber The card number
     */
    suspend fun delete(cardNumber: Long): Unit {
        val info = OperationInfo(
            service = "Cards",
            operation = "DeleteCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpDelete("/cards/${cardNumber}", operationName = info.operation)
        }) { Unit }
    }

    /**
     * assign operation
     * @param cardNumber The card number
     * @param body Request body
     */
    suspend fun assign(cardNumber: Long, body: AssignCardBody): Unit {
        val info = OperationInfo(
            service = "Cards",
            operation = "AssignCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpPost("/cards/${cardNumber}/assignments.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("assignee_id", kotlinx.serialization.json.JsonPrimitive(body.assigneeId))
            }), operationName = info.operation)
        }) { Unit }
    }

    /**
     * move operation
     * @param cardNumber The card number
     * @param body Request body
     */
    suspend fun move(cardNumber: Long, body: MoveCardBody): Card {
        val info = OperationInfo(
            service = "Cards",
            operation = "MoveCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        return request(info, {
            httpPatch("/cards/${cardNumber}/board.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("board_id", kotlinx.serialization.json.JsonPrimitive(body.boardId))
                body.columnId?.let { put("column_id", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<Card>(body)
        }
    }

    /**
     * close operation
     * @param cardNumber The card number
     */
    suspend fun close(cardNumber: Long): Unit {
        val info = OperationInfo(
            service = "Cards",
            operation = "CloseCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpPost("/cards/${cardNumber}/closure.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * reopen operation
     * @param cardNumber The card number
     */
    suspend fun reopen(cardNumber: Long): Unit {
        val info = OperationInfo(
            service = "Cards",
            operation = "ReopenCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpDelete("/cards/${cardNumber}/closure.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * gold operation
     * @param cardNumber The card number
     */
    suspend fun gold(cardNumber: Long): Unit {
        val info = OperationInfo(
            service = "Cards",
            operation = "GoldCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpPost("/cards/${cardNumber}/goldness.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * ungold operation
     * @param cardNumber The card number
     */
    suspend fun ungold(cardNumber: Long): Unit {
        val info = OperationInfo(
            service = "Cards",
            operation = "UngoldCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpDelete("/cards/${cardNumber}/goldness.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * deleteImage operation
     * @param cardNumber The card number
     */
    suspend fun deleteImage(cardNumber: Long): Unit {
        val info = OperationInfo(
            service = "Cards",
            operation = "DeleteCardImage",
            resourceType = "card_image",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpDelete("/cards/${cardNumber}/image.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * postpone operation
     * @param cardNumber The card number
     */
    suspend fun postpone(cardNumber: Long): Unit {
        val info = OperationInfo(
            service = "Cards",
            operation = "PostponeCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpPost("/cards/${cardNumber}/not_now.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * pin operation
     * @param cardNumber The card number
     */
    suspend fun pin(cardNumber: Long): Unit {
        val info = OperationInfo(
            service = "Cards",
            operation = "PinCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpPost("/cards/${cardNumber}/pin.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * unpin operation
     * @param cardNumber The card number
     */
    suspend fun unpin(cardNumber: Long): Unit {
        val info = OperationInfo(
            service = "Cards",
            operation = "UnpinCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpDelete("/cards/${cardNumber}/pin.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * selfAssign operation
     * @param cardNumber The card number
     */
    suspend fun selfAssign(cardNumber: Long): Unit {
        val info = OperationInfo(
            service = "Cards",
            operation = "SelfAssignCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpPost("/cards/${cardNumber}/self_assignment.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * tag operation
     * @param cardNumber The card number
     * @param body Request body
     */
    suspend fun tag(cardNumber: Long, body: TagCardBody): Unit {
        val info = OperationInfo(
            service = "Cards",
            operation = "TagCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpPost("/cards/${cardNumber}/taggings.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("tag_title", kotlinx.serialization.json.JsonPrimitive(body.tagTitle))
            }), operationName = info.operation)
        }) { Unit }
    }

    /**
     * triage operation
     * @param cardNumber The card number
     * @param body Request body
     */
    suspend fun triage(cardNumber: Long, body: TriageCardBody): Unit {
        val info = OperationInfo(
            service = "Cards",
            operation = "TriageCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpPost("/cards/${cardNumber}/triage.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                body.columnId?.let { put("column_id", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { Unit }
    }

    /**
     * untriage operation
     * @param cardNumber The card number
     */
    suspend fun untriage(cardNumber: Long): Unit {
        val info = OperationInfo(
            service = "Cards",
            operation = "UnTriageCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpDelete("/cards/${cardNumber}/triage.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * watch operation
     * @param cardNumber The card number
     */
    suspend fun watch(cardNumber: Long): Unit {
        val info = OperationInfo(
            service = "Cards",
            operation = "WatchCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpPost("/cards/${cardNumber}/watch.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * unwatch operation
     * @param cardNumber The card number
     */
    suspend fun unwatch(cardNumber: Long): Unit {
        val info = OperationInfo(
            service = "Cards",
            operation = "UnwatchCard",
            resourceType = "card",
            isMutation = true,
            boardId = null,
            resourceId = cardNumber,
        )
        request(info, {
            httpDelete("/cards/${cardNumber}/watch.json", operationName = info.operation)
        }) { Unit }
    }
}
