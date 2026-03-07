package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * Pin entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class Pin(
    val id: String,
    val card: CardRef,
    @SerialName("created_at") val createdAt: String
)
