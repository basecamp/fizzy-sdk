package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.models.*
import com.basecamp.fizzy.services.BaseService
import kotlinx.serialization.json.JsonElement

/**
 * Service for Devices operations.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
class DevicesService(client: AccountClient) : BaseService(client) {

    /**
     * register operation
     * @param body Request body
     */
    suspend fun register(body: RegisterDeviceBody): Unit {
        val info = OperationInfo(
            service = "Devices",
            operation = "RegisterDevice",
            resourceType = "device",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        request(info, {
            httpPost("/devices", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("token", kotlinx.serialization.json.JsonPrimitive(body.token))
                put("platform", kotlinx.serialization.json.JsonPrimitive(body.platform))
                body.name?.let { put("name", kotlinx.serialization.json.JsonPrimitive(it)) }
            }), operationName = info.operation)
        }) { Unit }
    }

    /**
     * unregister operation
     * @param deviceToken The device token
     */
    suspend fun unregister(deviceToken: String): Unit {
        val info = OperationInfo(
            service = "Devices",
            operation = "UnregisterDevice",
            resourceType = "device",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        request(info, {
            httpDelete("/devices/${deviceToken}", operationName = info.operation)
        }) { Unit }
    }
}
