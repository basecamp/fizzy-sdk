package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * Account entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class Account(
    val id: String,
    val name: String,
    val slug: String,
    @SerialName("created_at") val createdAt: String,
    val url: String,
    val user: User? = null
)
