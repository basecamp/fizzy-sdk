package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.models.*
import com.basecamp.fizzy.services.BaseService
import kotlinx.serialization.json.JsonElement

/**
 * Service for Columns operations.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
class ColumnsService(client: AccountClient) : BaseService(client) {

    /**
     * list operation
     * @param boardId The board ID
     */
    suspend fun list(boardId: String): List<Column> {
        val info = OperationInfo(
            service = "Columns",
            operation = "ListColumns",
            resourceType = "column",
            isMutation = false,
            boardId = boardId,
            resourceId = null,
        )
        return request(info, {
            httpGet("/boards/${boardId}/columns.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<List<Column>>(body)
        }
    }

    /**
     * create operation
     * @param boardId The board ID
     * @param body Request body
     */
    suspend fun create(boardId: String, body: CreateColumnBody): Column {
        val info = OperationInfo(
            service = "Columns",
            operation = "CreateColumn",
            resourceType = "column",
            isMutation = true,
            boardId = boardId,
            resourceId = null,
        )
        return request(info, {
            httpPost("/boards/${boardId}/columns.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("name", kotlinx.serialization.json.JsonPrimitive(body.name))
                body.color?.let { put("color", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<Column>(body)
        }
    }

    /**
     * get operation
     * @param boardId The board ID
     * @param columnId The column ID
     */
    suspend fun get(boardId: String, columnId: String): Column {
        val info = OperationInfo(
            service = "Columns",
            operation = "GetColumn",
            resourceType = "column",
            isMutation = false,
            boardId = boardId,
            resourceId = columnId,
        )
        return request(info, {
            httpGet("/boards/${boardId}/columns/${columnId}", operationName = info.operation)
        }) { body ->
            json.decodeFromString<Column>(body)
        }
    }

    /**
     * update operation
     * @param boardId The board ID
     * @param columnId The column ID
     * @param body Request body
     */
    suspend fun update(boardId: String, columnId: String, body: UpdateColumnBody): Column {
        val info = OperationInfo(
            service = "Columns",
            operation = "UpdateColumn",
            resourceType = "column",
            isMutation = true,
            boardId = boardId,
            resourceId = columnId,
        )
        return request(info, {
            httpPatch("/boards/${boardId}/columns/${columnId}", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                body.name?.let { put("name", kotlinx.serialization.json.JsonPrimitive(it)) }
                body.color?.let { put("color", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<Column>(body)
        }
    }

    /**
     * delete operation
     * @param boardId The board ID
     * @param columnId The column ID
     */
    suspend fun delete(boardId: String, columnId: String): Unit {
        val info = OperationInfo(
            service = "Columns",
            operation = "DeleteColumn",
            resourceType = "column",
            isMutation = true,
            boardId = boardId,
            resourceId = columnId,
        )
        request(info, {
            httpDelete("/boards/${boardId}/columns/${columnId}", operationName = info.operation)
        }) { Unit }
    }
}
