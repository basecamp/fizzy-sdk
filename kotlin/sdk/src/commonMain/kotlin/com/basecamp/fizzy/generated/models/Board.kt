package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * Board entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class Board(
    val id: String,
    val name: String,
    @SerialName("all_access") val allAccess: Boolean,
    @SerialName("created_at") val createdAt: String,
    val url: String,
    @SerialName("auto_postpone_period_in_days") val autoPostponePeriodInDays: Int = 0,
    @SerialName("public_description") val publicDescription: String? = null,
    @SerialName("public_description_html") val publicDescriptionHtml: String? = null,
    @SerialName("public_url") val publicUrl: String? = null,
    @SerialName("user_ids") val userIds: List<String> = emptyList(),
    val creator: User? = null
)
