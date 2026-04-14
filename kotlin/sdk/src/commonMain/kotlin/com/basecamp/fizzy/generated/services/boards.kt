package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.models.*
import com.basecamp.fizzy.services.BaseService
import kotlinx.serialization.json.JsonElement

/**
 * Service for Boards operations.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
class BoardsService(client: AccountClient) : BaseService(client) {

    /**
     * list operation
     * @param options Optional query parameters and pagination control
     */
    suspend fun list(options: PaginationOptions? = null): ListResult<Board> {
        val info = OperationInfo(
            service = "Boards",
            operation = "ListBoards",
            resourceType = "board",
            isMutation = false,
            boardId = null,
            resourceId = null,
        )
        return requestPaginated(info, options, {
            httpGet("/boards.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<List<Board>>(body)
        }
    }

    /**
     * create operation
     * @param body Request body
     */
    suspend fun create(body: CreateBoardBody): Board {
        val info = OperationInfo(
            service = "Boards",
            operation = "CreateBoard",
            resourceType = "board",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpPost("/boards.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("name", kotlinx.serialization.json.JsonPrimitive(body.name))
                body.allAccess?.let { put("all_access", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.autoPostponePeriodInDays?.let { put("auto_postpone_period_in_days", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.publicDescription?.let { put("public_description", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<Board>(body)
        }
    }

    /**
     * get operation
     * @param boardId The board ID
     */
    suspend fun get(boardId: String): Board {
        val info = OperationInfo(
            service = "Boards",
            operation = "GetBoard",
            resourceType = "board",
            isMutation = false,
            boardId = boardId,
            resourceId = null,
        )
        return request(info, {
            httpGet("/boards/${boardId}", operationName = info.operation)
        }) { body ->
            json.decodeFromString<Board>(body)
        }
    }

    /**
     * update operation
     * @param boardId The board ID
     * @param body Request body
     */
    suspend fun update(boardId: String, body: UpdateBoardBody): Board {
        val info = OperationInfo(
            service = "Boards",
            operation = "UpdateBoard",
            resourceType = "board",
            isMutation = true,
            boardId = boardId,
            resourceId = null,
        )
        return request(info, {
            httpPatch("/boards/${boardId}", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                body.name?.let { put("name", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.allAccess?.let { put("all_access", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.autoPostponePeriodInDays?.let { put("auto_postpone_period_in_days", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.publicDescription?.let { put("public_description", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.userIds?.let { put("user_ids", kotlinx.serialization.json.JsonArray(it.map { kotlinx.serialization.json.JsonPrimitive(it) })) }
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<Board>(body)
        }
    }

    /**
     * delete operation
     * @param boardId The board ID
     */
    suspend fun delete(boardId: String): Unit {
        val info = OperationInfo(
            service = "Boards",
            operation = "DeleteBoard",
            resourceType = "board",
            isMutation = true,
            boardId = boardId,
            resourceId = null,
        )
        request(info, {
            httpDelete("/boards/${boardId}", operationName = info.operation)
        }) { Unit }
    }

    /**
     * listBoardAccesses operation
     * @param boardId The board ID
     * @param options Optional query parameters and pagination control
     */
    suspend fun listBoardAccesses(boardId: String, options: ListBoardAccessesOptions? = null): BoardAccesses {
        val info = OperationInfo(
            service = "Boards",
            operation = "ListBoardAccesses",
            resourceType = "board_access",
            isMutation = false,
            boardId = boardId,
            resourceId = null,
        )
        val qs = buildQueryString(
            "page" to options?.page,
        )
        return request(info, {
            httpGet("/boards/${boardId}/accesses.json" + qs, operationName = info.operation)
        }) { body ->
            json.decodeFromString<BoardAccesses>(body)
        }
    }

    /**
     * publishBoard operation
     * @param boardId The board ID
     */
    suspend fun publishBoard(boardId: String): Unit {
        val info = OperationInfo(
            service = "Boards",
            operation = "PublishBoard",
            resourceType = "resource",
            isMutation = true,
            boardId = boardId,
            resourceId = null,
        )
        request(info, {
            httpPost("/boards/${boardId}/publication.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * unpublishBoard operation
     * @param boardId The board ID
     */
    suspend fun unpublishBoard(boardId: String): Unit {
        val info = OperationInfo(
            service = "Boards",
            operation = "UnpublishBoard",
            resourceType = "resource",
            isMutation = true,
            boardId = boardId,
            resourceId = null,
        )
        request(info, {
            httpDelete("/boards/${boardId}/publication.json", operationName = info.operation)
        }) { Unit }
    }
}
