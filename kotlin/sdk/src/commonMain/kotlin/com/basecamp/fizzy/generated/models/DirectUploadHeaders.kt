package com.basecamp.fizzy.generated.models

import kotlinx.serialization.Serializable

/**
 * DirectUploadHeaders entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class DirectUploadHeaders(
    val Content_Type: String,
    val Content_MD5: String? = null
)
