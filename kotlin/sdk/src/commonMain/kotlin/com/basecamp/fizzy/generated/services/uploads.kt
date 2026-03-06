package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.models.*
import com.basecamp.fizzy.services.BaseService
import kotlinx.serialization.json.JsonElement

/**
 * Service for Uploads operations.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
class UploadsService(client: AccountClient) : BaseService(client) {

    /**
     * createDirect operation
     * @param body Request body
     */
    suspend fun createDirect(body: CreateDirectUploadBody): DirectUpload {
        val info = OperationInfo(
            service = "Uploads",
            operation = "CreateDirectUpload",
            resourceType = "direct_upload",
            isMutation = true,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpPost("/rails/active_storage/direct_uploads", json.encodeToString(kotlinx.serialization.json.buildJsonObject {
                put("filename", kotlinx.serialization.json.JsonPrimitive(body.filename))
                put("content_type", kotlinx.serialization.json.JsonPrimitive(body.contentType))
                put("byte_size", kotlinx.serialization.json.JsonPrimitive(body.byteSize))
                put("checksum", kotlinx.serialization.json.JsonPrimitive(body.checksum))
            }), operationName = info.operation)
        }) { body ->
            json.decodeFromString<DirectUpload>(body)
        }
    }
}
