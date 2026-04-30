package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Tag entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class Tag(
    val id: String,
    val title: String,
    @SerialName("created_at") val createdAt: String,
    val url: String? = null
)
