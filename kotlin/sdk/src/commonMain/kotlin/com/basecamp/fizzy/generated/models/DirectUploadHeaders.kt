package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * DirectUploadHeaders entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class DirectUploadHeaders(
    @SerialName("Content-Type") val contentType: String,
    @SerialName("Content-MD5") val contentMD5: String? = null
)
