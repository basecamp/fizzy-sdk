package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * RichTextBody entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class RichTextBody(
    @SerialName("plain_text") val plainText: String,
    val html: String
)
