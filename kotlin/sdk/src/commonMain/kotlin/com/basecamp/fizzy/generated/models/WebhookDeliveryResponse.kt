package com.basecamp.fizzy.generated.models

import kotlinx.serialization.Serializable

/**
 * WebhookDeliveryResponse entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class WebhookDeliveryResponse(
    val code: Int = 0,
    val error: String? = null
)
