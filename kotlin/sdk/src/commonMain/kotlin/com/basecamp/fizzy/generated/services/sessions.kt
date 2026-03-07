package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.models.*
import com.basecamp.fizzy.services.BaseService
import kotlinx.serialization.json.JsonElement

/**
 * Service for Sessions operations.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
class SessionsService(client: AccountClient) : BaseService(client) {

    /**
     * create operation
     * @param body Request body
     */
    suspend fun create(body: CreateSessionBody): PendingAuthentication {
        val info = OperationInfo(
            service = "Sessions",
            operation = "CreateSession",
            resourceType = "session",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpPostRoot("/session.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("email_address", kotlinx.serialization.json.JsonPrimitive(body.emailAddress))
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<PendingAuthentication>(body)
        }
    }

    /**
     * destroy operation
     */
    suspend fun destroy(): Unit {
        val info = OperationInfo(
            service = "Sessions",
            operation = "DestroySession",
            resourceType = "session",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        request(info, {
            httpDeleteRoot("/session.json", operationName = info.operation)
        }) { Unit }
    }

    /**
     * redeemMagicLink operation
     * @param body Request body
     */
    suspend fun redeemMagicLink(body: RedeemMagicLinkBody): SessionAuthorization {
        val info = OperationInfo(
            service = "Sessions",
            operation = "RedeemMagicLink",
            resourceType = "magic_link",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpPostRoot("/session/magic_link.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("token", kotlinx.serialization.json.JsonPrimitive(body.token))
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<SessionAuthorization>(body)
        }
    }

    /**
     * completeSignup operation
     * @param body Request body
     */
    suspend fun completeSignup(body: CompleteSignupBody): User {
        val info = OperationInfo(
            service = "Sessions",
            operation = "CompleteSignup",
            resourceType = "signup",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpPostRoot("/signup/completion.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("name", kotlinx.serialization.json.JsonPrimitive(body.name))
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<User>(body)
        }
    }
}
