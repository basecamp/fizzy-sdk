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
    val autoPostponePeriodInDays: Int? = null,
    val publicDescription: String? = null
)

/** Request body for UpdateBoard. */
data class UpdateBoardBody(
    val name: String? = null,
    val allAccess: Boolean? = null,
    val autoPostponePeriodInDays: Int? = null,
    val publicDescription: String? = null,
    val userIds: List<String>? = null
)

/** Options for ListBoardAccesses. */
data class ListBoardAccessesOptions(
    val page: Long? = null
) {
}

/** Options for ListActivities. */
data class ListActivitiesOptions(
    val creatorIds: List<String>? = null,
    val boardIds: List<String>? = null,
    val maxItems: Int? = null
) {
    fun toPaginationOptions(): PaginationOptions = PaginationOptions(maxItems = maxItems)
}

/** Options for ListCards. */
data class ListCardsOptions(
    val boardIds: List<String>? = null,
    val tagIds: List<String>? = null,
    val assigneeIds: List<String>? = null,
    val creatorIds: List<String>? = null,
    val closerIds: List<String>? = null,
    val cardIds: List<String>? = null,
    val indexedBy: String? = null,
    val sortedBy: String? = null,
    val assignmentStatus: String? = null,
    val creation: String? = null,
    val closure: String? = null,
    val terms: List<String>? = null,
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

/** Request body for CreateAccessToken. */
data class CreateAccessTokenBody(
    val description: String,
    val permission: String
)

/** Request body for UpdateAccountEntropy. */
data class UpdateAccountEntropyBody(
    val autoPostponePeriodInDays: Int? = null
)

/** Request body for UpdateJoinCode. */
data class UpdateJoinCodeBody(
    val usageLimit: Int? = null
)

/** Request body for UpdateAccountSettings. */
data class UpdateAccountSettingsBody(
    val name: String? = null
)

/** Request body for UpdateBoardEntropy. */
data class UpdateBoardEntropyBody(
    val autoPostponePeriodInDays: Int? = null
)

/** Request body for UpdateBoardInvolvement. */
data class UpdateBoardInvolvementBody(
    val involvement: String? = null
)

/** Request body for UpdateNotificationSettings. */
data class UpdateNotificationSettingsBody(
    val bundleEmailFrequency: String? = null
)

/** Request body for CreatePushSubscription. */
data class CreatePushSubscriptionBody(
    val endpoint: String,
    val p256dhKey: String,
    val authKey: String
)

/** Request body for UpdateUserRole. */
data class UpdateUserRoleBody(
    val role: String
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
    val fullName: String
)

/** Request body for CompleteJoin. */
data class CompleteJoinBody(
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

/** Request body for RequestEmailAddressChange. */
data class RequestEmailAddressChangeBody(
    val emailAddress: String
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

