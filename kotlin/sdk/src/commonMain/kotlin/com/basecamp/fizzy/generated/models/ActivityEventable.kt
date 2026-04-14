package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * ActivityEventable entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class ActivityEventable(
    val id: String,
    val url: String,
    val number: Int = 0,
    val title: String? = null,
    val status: String? = null,
    val description: String? = null,
    @SerialName("description_html") val descriptionHtml: String? = null,
    @SerialName("image_url") val imageUrl: String? = null,
    @SerialName("has_attachments") val hasAttachments: Boolean = false,
    val tags: List<String> = emptyList(),
    val closed: Boolean = false,
    val postponed: Boolean = false,
    val golden: Boolean = false,
    @SerialName("last_active_at") val lastActiveAt: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null,
    val body: RichTextBody? = null,
    val creator: User? = null,
    val card: CardRef? = null,
    val board: Board? = null,
    val column: Column? = null,
    val assignees: List<User> = emptyList(),
    @SerialName("has_more_assignees") val hasMoreAssignees: Boolean = false,
    @SerialName("comments_url") val commentsUrl: String? = null,
    @SerialName("reactions_url") val reactionsUrl: String? = null,
    val steps: List<Step> = emptyList()
)
