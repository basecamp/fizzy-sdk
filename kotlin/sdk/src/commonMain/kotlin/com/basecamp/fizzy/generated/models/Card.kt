package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * Card entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class Card(
    val id: String,
    val number: Int,
    val title: String,
    val status: String,
    @SerialName("has_attachments") val hasAttachments: Boolean,
    val closed: Boolean,
    val postponed: Boolean,
    val golden: Boolean,
    @SerialName("created_at") val createdAt: String,
    val url: String,
    val description: String? = null,
    @SerialName("description_html") val descriptionHtml: String? = null,
    @SerialName("image_url") val imageUrl: String? = null,
    val tags: List<String> = emptyList(),
    @SerialName("last_active_at") val lastActiveAt: String? = null,
    val board: BoardSummary? = null,
    val column: ColumnSummary? = null,
    val creator: UserSummary? = null,
    val assignees: List<UserSummary> = emptyList(),
    @SerialName("has_more_assignees") val hasMoreAssignees: Boolean = false,
    @SerialName("comments_url") val commentsUrl: String? = null,
    @SerialName("reactions_url") val reactionsUrl: String? = null,
    val steps: List<Step> = emptyList()
)
