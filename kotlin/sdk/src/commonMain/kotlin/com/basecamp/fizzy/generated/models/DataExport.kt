package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * DataExport entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class DataExport(
    val id: String,
    val status: String,
    @SerialName("created_at") val createdAt: String,
    @SerialName("download_url") val downloadUrl: String? = null
)
