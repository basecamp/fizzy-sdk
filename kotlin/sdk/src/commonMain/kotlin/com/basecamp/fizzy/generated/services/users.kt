package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.models.*
import com.basecamp.fizzy.services.BaseService
import kotlinx.serialization.json.JsonElement

/**
 * Service for Users operations.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
class UsersService(client: AccountClient) : BaseService(client) {

    /**
     * list operation
     */
    suspend fun list(): List<User> {
        val info = OperationInfo(
            service = "Users",
            operation = "ListUsers",
            resourceType = "user",
            isMutation = false,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpGet("/users.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<List<User>>(body)
        }
    }

    /**
     * get operation
     * @param userId The user ID
     */
    suspend fun get(userId: Long): User {
        val info = OperationInfo(
            service = "Users",
            operation = "GetUser",
            resourceType = "user",
            isMutation = false,
            boardId = null,
            resourceId = userId,
        )
        return request(info, {
            httpGet("/users/${userId}", operationName = info.operation)
        }) { body ->
            json.decodeFromString<User>(body)
        }
    }

    /**
     * update operation
     * @param userId The user ID
     * @param body Request body
     */
    suspend fun update(userId: Long, body: UpdateUserBody): User {
        val info = OperationInfo(
            service = "Users",
            operation = "UpdateUser",
            resourceType = "user",
            isMutation = true,
            boardId = null,
            resourceId = userId,
        )
        return request(info, {
            httpPut("/users/${userId}", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                body.name?.let { put("name", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<User>(body)
        }
    }

    /**
     * deactivate operation
     * @param userId The user ID
     */
    suspend fun deactivate(userId: Long): Unit {
        val info = OperationInfo(
            service = "Users",
            operation = "DeactivateUser",
            resourceType = "user",
            isMutation = true,
            boardId = null,
            resourceId = userId,
        )
        request(info, {
            httpDelete("/users/${userId}", operationName = info.operation)
        }) { Unit }
    }
}
