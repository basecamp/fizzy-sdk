package com.basecamp.fizzy.generated.services

import com.basecamp.fizzy.PaginationOptions
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

/**
 * Request body and options classes for generated service methods.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */

/** Request body for CreateBoard. */
data class CreateBoardBody(
    val name: String,
    val allAccess: Boolean? = null,
    val autoPostponePeriod: Int? = null
)

/** Request body for UpdateBoard. */
data class UpdateBoardBody(
    val name: String? = null,
    val allAccess: Boolean? = null,
    val autoPostponePeriod: Int? = null
)

/** Options for ListCards. */
data class ListCardsOptions(
    val boardId: String? = null,
    val columnId: String? = null,
    val assigneeId: String? = null,
    val tag: String? = null,
    val status: String? = null,
    val q: String? = null,
    val maxItems: Int? = null
) {
    fun toPaginationOptions(): PaginationOptions = PaginationOptions(maxItems = maxItems)
}

/** Request body for CreateCard. */
data class CreateCardBody(
    val title: String,
    val boardId: String? = null,
    val columnId: String? = null,
    val description: String? = null,
    val assigneeIds: List<String>? = null,
    val tagNames: List<String>? = null,
    val image: String? = null,
    val createdAt: String? = null,
    val lastActiveAt: String? = null
)

/** Request body for UpdateCard. */
data class UpdateCardBody(
    val title: String? = null,
    val description: String? = null,
    val columnId: String? = null,
    val image: String? = null,
    val createdAt: String? = null
)

/** Request body for AssignCard. */
data class AssignCardBody(
    val assigneeId: String
)

/** Request body for MoveCard. */
data class MoveCardBody(
    val boardId: String,
    val columnId: String? = null
)

/** Request body for TagCard. */
data class TagCardBody(
    val tagTitle: String
)

/** Request body for TriageCard. */
data class TriageCardBody(
    val columnId: String? = null
)

/** Request body for CreateColumn. */
data class CreateColumnBody(
    val name: String,
    val color: String? = null
)

/** Request body for UpdateColumn. */
data class UpdateColumnBody(
    val name: String? = null,
    val color: String? = null
)

/** Request body for CreateComment. */
data class CreateCommentBody(
    val body: String,
    val createdAt: String? = null
)

/** Request body for UpdateComment. */
data class UpdateCommentBody(
    val body: String
)

/** Request body for RegisterDevice. */
data class RegisterDeviceBody(
    val token: String,
    val platform: String,
    val name: String? = null
)

/** Options for ListNotifications. */
data class ListNotificationsOptions(
    val read: Boolean? = null,
    val maxItems: Int? = null
) {
    fun toPaginationOptions(): PaginationOptions = PaginationOptions(maxItems = maxItems)
}

/** Request body for BulkReadNotifications. */
data class BulkReadNotificationsBody(
    val notificationIds: List<String>? = null
)

/** Options for GetNotificationTray. */
data class GetNotificationTrayOptions(
    val includeRead: Boolean? = null
) {
}

/** Request body for CreateCommentReaction. */
data class CreateCommentReactionBody(
    val content: String
)

/** Request body for CreateCardReaction. */
data class CreateCardReactionBody(
    val content: String
)

/** Request body for CreateSession. */
data class CreateSessionBody(
    val emailAddress: String
)

/** Request body for RedeemMagicLink. */
data class RedeemMagicLinkBody(
    val token: String
)

/** Request body for CompleteSignup. */
data class CompleteSignupBody(
    val name: String
)

/** Request body for CreateStep. */
data class CreateStepBody(
    val content: String,
    val completed: Boolean? = null
)

/** Request body for UpdateStep. */
data class UpdateStepBody(
    val content: String? = null,
    val completed: Boolean? = null
)

/** Request body for CreateDirectUpload. */
data class CreateDirectUploadBody(
    val filename: String,
    val contentType: String,
    val byteSize: Long,
    val checksum: String
)

/** Request body for UpdateUser. */
data class UpdateUserBody(
    val name: String? = null
)

/** Request body for CreateWebhook. */
data class CreateWebhookBody(
    val name: String,
    val url: String,
    val subscribedActions: List<String>? = null
)

/** Request body for UpdateWebhook. */
data class UpdateWebhookBody(
    val name: String? = null,
    val url: String? = null,
    val subscribedActions: List<String>? = null
)

