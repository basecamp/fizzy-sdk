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
     * @param options Optional query parameters and pagination control
     */
    suspend fun list(options: PaginationOptions? = null): ListResult<User> {
        val info = OperationInfo(
            service = "Users",
            operation = "ListUsers",
            resourceType = "user",
            isMutation = false,
            boardId = null,
            resourceId = null,
        )
        return requestPaginated(info, options, {
            httpGet("/users.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<List<User>>(body)
        }
    }

    /**
     * get operation
     * @param userId The user ID
     */
    suspend fun get(userId: String): User {
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
    suspend fun update(userId: String, body: UpdateUserBody): User {
        val info = OperationInfo(
            service = "Users",
            operation = "UpdateUser",
            resourceType = "user",
            isMutation = true,
            boardId = null,
            resourceId = userId,
        )
        return request(info, {
            httpPatch("/users/${userId}", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
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
    suspend fun deactivate(userId: String): Unit {
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

    /**
     * createUserDataExport operation
     * @param userId The user ID
     */
    suspend fun createUserDataExport(userId: String): DataExport {
        val info = OperationInfo(
            service = "Users",
            operation = "CreateUserDataExport",
            resourceType = "user_data_export",
            isMutation = true,
            boardId = null,
            resourceId = userId,
        )
        return request(info, {
            httpPost("/users/${userId}/data_exports.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<DataExport>(body)
        }
    }

    /**
     * userDataExport operation
     * @param userId The user ID
     * @param exportId The export ID
     */
    suspend fun userDataExport(userId: String, exportId: String): DataExport {
        val info = OperationInfo(
            service = "Users",
            operation = "GetUserDataExport",
            resourceType = "user_data_export",
            isMutation = false,
            boardId = null,
            resourceId = userId,
        )
        return request(info, {
            httpGet("/users/${userId}/data_exports/${exportId}", operationName = info.operation)
        }) { body ->
            json.decodeFromString<DataExport>(body)
        }
    }

    /**
     * requestEmailAddressChange operation
     * @param userId The user ID
     * @param body Request body
     */
    suspend fun requestEmailAddressChange(userId: String, body: RequestEmailAddressChangeBody): Unit {
        val info = OperationInfo(
            service = "Users",
            operation = "RequestEmailAddressChange",
            resourceType = "resource",
            isMutation = true,
            boardId = null,
            resourceId = userId,
        )
        request(info, {
            httpPost("/users/${userId}/email_addresses.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("email_address", kotlinx.serialization.json.JsonPrimitive(body.emailAddress))
            }), operationName = info.operation)
        }) { Unit }
    }

    /**
     * confirmEmailAddressChange operation
     * @param userId The user ID
     * @param emailAddressToken The email address token
     */
    suspend fun confirmEmailAddressChange(userId: String, emailAddressToken: String): Unit {
        val info = OperationInfo(
            service = "Users",
            operation = "ConfirmEmailAddressChange",
            resourceType = "resource",
            isMutation = true,
            boardId = null,
            resourceId = userId,
        )
        request(info, {
            httpPost("/users/${userId}/email_addresses/${emailAddressToken}/confirmation.json", operationName = info.operation)
        }) { Unit }
    }
}
