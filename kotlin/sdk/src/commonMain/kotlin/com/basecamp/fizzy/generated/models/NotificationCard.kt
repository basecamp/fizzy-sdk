package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * NotificationCard entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class NotificationCard(
    val id: String,
    val number: Int,
    val title: String,
    val status: String,
    val closed: Boolean,
    val postponed: Boolean,
    val url: String,
    @SerialName("board_name") val boardName: String? = null,
    val column: Column? = null
)
