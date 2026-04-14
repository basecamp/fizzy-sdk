package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * ActivityParticulars entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class ActivityParticulars(
    @SerialName("assignee_ids") val assigneeIds: List<String> = emptyList(),
    @SerialName("old_board") val oldBoard: String? = null,
    @SerialName("new_board") val newBoard: String? = null,
    @SerialName("old_title") val oldTitle: String? = null,
    @SerialName("new_title") val newTitle: String? = null,
    val column: String? = null
)
