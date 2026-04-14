package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * WebhookDelivery entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class WebhookDelivery(
    val id: String,
    val state: String,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String,
    val request: WebhookDeliveryRequest? = null,
    val response: WebhookDeliveryResponse? = null,
    val event: WebhookDeliveryEvent? = null
)
