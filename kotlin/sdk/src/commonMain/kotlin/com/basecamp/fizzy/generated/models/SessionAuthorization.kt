package com.basecamp.fizzy.generated.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * SessionAuthorization entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class SessionAuthorization(
    @SerialName("session_token") val sessionToken: String,
    @SerialName("requires_signup_completion") val requiresSignupCompletion: Boolean
)
