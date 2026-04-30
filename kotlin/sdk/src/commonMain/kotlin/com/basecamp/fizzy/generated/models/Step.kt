package com.basecamp.fizzy.generated.models

import kotlinx.serialization.Serializable

/**
 * Step entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class Step(
    val id: String,
    val content: String,
    val completed: Boolean
)
