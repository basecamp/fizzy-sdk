package com.basecamp.fizzy.generated.models

import kotlinx.serialization.Serializable

/**
 * DirectUploadMetadata entity from the Fizzy API.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */
@Serializable
data class DirectUploadMetadata(
    val url: String,
    val headers: DirectUploadHeaders
)
