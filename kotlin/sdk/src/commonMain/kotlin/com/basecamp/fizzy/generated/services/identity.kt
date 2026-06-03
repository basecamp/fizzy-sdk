package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.models.*
import com.basecamp.fizzy.services.BaseService
import kotlinx.serialization.json.JsonElement

/**
 * Service for Identity operations.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
class IdentityService(client: AccountClient) : BaseService(client) {

    /**
     * me operation
     */
    suspend fun me(): Identity {
        val info = OperationInfo(
            service = "Identity",
            operation = "GetMyIdentity",
            resourceType = "my_identity",
            isMutation = false,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpGetRoot("/my/identity.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<Identity>(body)
        }
    }

    /**
     * updateTimezone operation
     * @param body Request body
     */
    suspend fun updateTimezone(body: UpdateMyTimezoneBody): Unit {
        val info = OperationInfo(
            service = "Identity",
            operation = "UpdateMyTimezone",
            resourceType = "my_timezone",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        request(info, {
            httpPatch("/my/timezone.json", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("timezone_name", kotlinx.serialization.json.JsonPrimitive(body.timezoneName))
            }), operationName = info.operation)
        }) { Unit }
    }
}
