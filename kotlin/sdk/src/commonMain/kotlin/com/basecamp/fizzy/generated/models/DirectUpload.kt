package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * DirectUpload entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class DirectUpload(
    val id: String,
    val key: String,
    val filename: String,
    @SerialName("content_type") val contentType: String,
    @SerialName("byte_size") val byteSize: Long,
    val checksum: String,
    @SerialName("direct_upload") val directUpload: DirectUploadMetadata
)
