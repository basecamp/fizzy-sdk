package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * BoardAccesses entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class BoardAccesses(
    @SerialName("board_id") val boardId: String,
    @SerialName("all_access") val allAccess: Boolean,
    val users: List<BoardAccessUser>
)
