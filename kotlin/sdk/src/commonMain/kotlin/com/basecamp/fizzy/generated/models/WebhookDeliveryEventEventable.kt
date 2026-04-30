package com.basecamp.fizzy.generated.models

import kotlinx.serialization.Serializable

/**
 * WebhookDeliveryEventEventable entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class WebhookDeliveryEventEventable(
    val type: String,
    val id: String,
    val url: String
)
