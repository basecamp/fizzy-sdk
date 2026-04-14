package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * BoardAccessUser entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class BoardAccessUser(
    val id: String,
    val name: String,
    val role: String,
    val active: Boolean,
    @SerialName("email_address") val emailAddress: String,
    @SerialName("created_at") val createdAt: String,
    val url: String,
    @SerialName("has_access") val hasAccess: Boolean,
    @SerialName("avatar_url") val avatarUrl: String? = null,
    val involvement: String? = null
)
