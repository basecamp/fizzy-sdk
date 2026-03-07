package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * Notification entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class Notification(
    val id: String,
    @SerialName("unread_count") val unreadCount: Int,
    val read: Boolean,
    @SerialName("created_at") val createdAt: String,
    @SerialName("source_type") val sourceType: String,
    val creator: UserSummary,
    val url: String,
    @SerialName("read_at") val readAt: String? = null,
    val card: NotificationCard? = null
)
