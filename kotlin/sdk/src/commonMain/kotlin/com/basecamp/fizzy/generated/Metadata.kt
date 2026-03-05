package com.basecamp.fizzy.generated

/**
 * Per-operation metadata from behavior-model.json.
 *
 * This is a stub file. Run the generator to produce the full version
 * with per-operation retry configuration.
 *
 * @generated from behavior-model.json -- do not edit directly
 */
object Metadata {

    data class RetryConfig(
        val maxRetries: Int,
        val baseDelayMs: Long,
        val backoff: String,
        val retryOn: Set<Int>,
    )

    data class OperationConfig(
        val idempotent: Boolean,
        val retry: RetryConfig?,
    )

    val operations: Map<String, OperationConfig> = mapOf(
        // Boards
        "ListBoards" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "GetBoard" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "CreateBoard" to OperationConfig(false, null),
        "UpdateBoard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "DeleteBoard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),

        // Columns
        "ListColumns" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "GetColumn" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "CreateColumn" to OperationConfig(false, null),
        "UpdateColumn" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),

        // Cards
        "ListCards" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "GetCard" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "CreateCard" to OperationConfig(false, null),
        "UpdateCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "DeleteCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "CloseCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "ReopenCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "PostponeCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "TriageCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "UnTriageCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "GoldCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "UngoldCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "AssignCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "SelfAssignCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "TagCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "WatchCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "UnwatchCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "PinCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "UnpinCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "MoveCard" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "DeleteCardImage" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),

        // Comments
        "ListComments" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "GetComment" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "CreateComment" to OperationConfig(false, null),
        "UpdateComment" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "DeleteComment" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),

        // Steps
        "CreateStep" to OperationConfig(false, null),
        "GetStep" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "UpdateStep" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "DeleteStep" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),

        // Reactions
        "ListCardReactions" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "CreateCardReaction" to OperationConfig(false, null),
        "DeleteCardReaction" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "ListCommentReactions" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "CreateCommentReaction" to OperationConfig(false, null),
        "DeleteCommentReaction" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),

        // Notifications
        "ListNotifications" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "ReadNotification" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "UnreadNotification" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "BulkReadNotifications" to OperationConfig(true, null),
        "GetNotificationTray" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),

        // Tags
        "ListTags" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),

        // Users
        "ListUsers" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "GetUser" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "UpdateUser" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "DeactivateUser" to OperationConfig(true, null),

        // Pins
        "ListPins" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),

        // Uploads
        "CreateDirectUpload" to OperationConfig(false, null),

        // Webhooks
        "ListWebhooks" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "GetWebhook" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "CreateWebhook" to OperationConfig(false, null),
        "UpdateWebhook" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "DeleteWebhook" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "ActivateWebhook" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),

        // Identity
        "GetMyIdentity" to OperationConfig(false, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),

        // Sessions
        "CreateSession" to OperationConfig(false, null),
        "RedeemMagicLink" to OperationConfig(false, null),
        "DestroySession" to OperationConfig(true, null),
        "CompleteSignup" to OperationConfig(false, null),

        // Devices
        "RegisterDevice" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
        "UnregisterDevice" to OperationConfig(true, RetryConfig(3, 1000L, "exponential", setOf(429, 503))),
    )
}
