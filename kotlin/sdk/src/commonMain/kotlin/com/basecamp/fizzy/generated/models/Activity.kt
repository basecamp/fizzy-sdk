package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * Activity entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class Activity(
    val id: String,
    val action: String,
    @SerialName("created_at") val createdAt: String,
    val description: String,
    val particulars: ActivityParticulars,
    val url: String,
    @SerialName("eventable_type") val eventableType: String,
    val eventable: ActivityEventable,
    val board: Board,
    val creator: User
)
