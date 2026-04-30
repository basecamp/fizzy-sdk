package com.basecamp.fizzy.generated.models

import kotlinx.serialization.Serializable

/**
 * Reaction entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class Reaction(
    val id: String,
    val content: String,
    val reacter: User,
    val url: String
)
