package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.models.*
import com.basecamp.fizzy.services.BaseService
import kotlinx.serialization.json.JsonElement

/**
 * Service for Pins operations.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
class PinsService(client: AccountClient) : BaseService(client) {

    /**
     * list operation
     */
    suspend fun list(): List<Pin> {
        val info = OperationInfo(
            service = "Pins",
            operation = "ListPins",
            resourceType = "pin",
            isMutation = false,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpGetRoot("/my/pins.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<List<Pin>>(body)
        }
    }
}
