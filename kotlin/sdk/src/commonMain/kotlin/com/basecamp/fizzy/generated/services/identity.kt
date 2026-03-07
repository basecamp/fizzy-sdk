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
}
