package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * Comment entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class Comment(
    val id: String,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String,
    val body: RichTextBody,
    val creator: UserSummary,
    val url: String,
    val card: CardRef? = null,
    @SerialName("reactions_url") val reactionsUrl: String? = null
)
