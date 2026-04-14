package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * Webhook entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class Webhook(
    val id: String,
    val name: String,
    @SerialName("payload_url") val payloadUrl: String,
    val url: String,
    @SerialName("subscribed_actions") val subscribedActions: List<String>,
    @SerialName("signing_secret") val signingSecret: String,
    val active: Boolean,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String? = null,
    val board: Board? = null
)
