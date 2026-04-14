package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * WebhookDeliveryEvent entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class WebhookDeliveryEvent(
    val id: String,
    val action: String,
    @SerialName("created_at") val createdAt: String,
    val creator: WebhookDeliveryEventCreator? = null,
    val eventable: WebhookDeliveryEventEventable? = null
)
