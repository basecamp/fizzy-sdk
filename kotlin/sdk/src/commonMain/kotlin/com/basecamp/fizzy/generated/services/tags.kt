package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.models.*
import com.basecamp.fizzy.services.BaseService
import kotlinx.serialization.json.JsonElement

/**
 * Service for Tags operations.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
class TagsService(client: AccountClient) : BaseService(client) {

    /**
     * list operation
     */
    suspend fun list(): List<Tag> {
        val info = OperationInfo(
            service = "Tags",
            operation = "ListTags",
            resourceType = "tag",
            isMutation = false,
            boardId = null,
            resourceId = null,
        )
        return request(info, {
            httpGet("/tags.json", operationName = info.operation)
        }) { body ->
            json.decodeFromString<List<Tag>>(body)
        }
    }
}
