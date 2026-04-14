package com.basecamp.fizzy.generator

/**
 * Tag to service name mapping for Fizzy's 15 services.
 *
 * Fizzy operations are grouped by tag in the OpenAPI spec. These mappings
 * control which Kotlin service class each operation belongs to.
 */
val TAG_TO_SERVICE = mapOf(
    "Identity" to "Identity",
    "Boards" to "Boards",
    "Columns" to "Columns",
    "Cards" to "Cards",
    "Comments" to "Comments",
    "Steps" to "Steps",
    "Reactions" to "Reactions",
    "Notifications" to "Notifications",
    "Tags" to "Tags",
    "Users" to "Users",
    "Pins" to "Pins",
    "Uploads" to "Uploads",
    "Webhooks" to "Webhooks",
    "Sessions" to "Sessions",
    "Devices" to "Devices",
)

/** Explicit overrides for operations that don't follow suffix patterns. */
private val OPERATION_SERVICE_OVERRIDES = mapOf(
    "GetMyIdentity" to "Identity",
    "CreateDirectUpload" to "Uploads",
    "RedeemMagicLink" to "Sessions",
    "CompleteSignup" to "Sessions",
    "CompleteJoin" to "Sessions",
    "GetNotificationTray" to "Notifications",
    "BulkReadNotifications" to "Notifications",
    "DeleteCardImage" to "Cards",
    "ListBoardAccesses" to "Boards",
    "ListActivities" to "Cards",
    "RequestEmailAddressChange" to "Users",
    "ConfirmEmailAddressChange" to "Users",
    "CreateUserDataExport" to "Users",
    "GetUserDataExport" to "Users",
    "ListWebhookDeliveries" to "Webhooks",
)

/** Suffix map for deriving service from operationId (longest match first). */
private val SERVICE_SUFFIXES = listOf(
    "CommentReactions" to "Reactions",
    "CommentReaction" to "Reactions",
    "CardReactions" to "Reactions",
    "CardReaction" to "Reactions",
    "Notifications" to "Notifications",
    "Notification" to "Notifications",
    "Comments" to "Comments",
    "Comment" to "Comments",
    "Webhooks" to "Webhooks",
    "Webhook" to "Webhooks",
    "Columns" to "Columns",
    "Column" to "Columns",
    "Boards" to "Boards",
    "Board" to "Boards",
    "Cards" to "Cards",
    "Card" to "Cards",
    "Steps" to "Steps",
    "Step" to "Steps",
    "Users" to "Users",
    "User" to "Users",
    "Tags" to "Tags",
    "Pins" to "Pins",
    "Session" to "Sessions",
    "Device" to "Devices",
)

/** Derives service name from operationId when tags are absent. */
fun deriveServiceName(operationId: String): String {
    OPERATION_SERVICE_OVERRIDES[operationId]?.let { return it }
    for ((suffix, service) in SERVICE_SUFFIXES) {
        if (operationId.endsWith(suffix)) return service
    }
    return "Miscellaneous"
}

/**
 * Service split configuration -- some tags map to multiple service classes.
 *
 * Fizzy's operations are cleanly grouped, but reactions span card and comment
 * contexts. We keep them together in a single Reactions service.
 */
val SERVICE_SPLITS: Map<String, Map<String, List<String>>> = mapOf(
    "Reactions" to mapOf(
        "Reactions" to listOf(
            "ListCardReactions", "CreateCardReaction", "DeleteCardReaction",
            "ListCommentReactions", "CreateCommentReaction", "DeleteCommentReaction",
        ),
    ),
)

/**
 * Verb extraction patterns for operationId -> method name mapping.
 */
val VERB_PATTERNS = listOf(
    "Bulk" to "bulk",
    "Subscribe" to "subscribe",
    "Unsubscribe" to "unsubscribe",
    "List" to "list",
    "Get" to "get",
    "Create" to "create",
    "Update" to "update",
    "Delete" to "delete",
    "Close" to "close",
    "Reopen" to "reopen",
    "Postpone" to "postpone",
    "Triage" to "triage",
    "UnTriage" to "untriage",
    "Gold" to "gold",
    "Ungold" to "ungold",
    "Assign" to "assign",
    "SelfAssign" to "selfAssign",
    "Tag" to "tag",
    "Watch" to "watch",
    "Unwatch" to "unwatch",
    "Pin" to "pin",
    "Unpin" to "unpin",
    "Move" to "move",
    "Read" to "read",
    "Unread" to "unread",
    "Activate" to "activate",
    "Deactivate" to "deactivate",
    "Register" to "register",
    "Unregister" to "unregister",
    "Redeem" to "redeem",
    "Destroy" to "destroy",
    "Complete" to "complete",
    "Search" to "search",
)

/**
 * Method name overrides for specific operationIds.
 */
val METHOD_NAME_OVERRIDES = mapOf(
    "GetMyIdentity" to "me",
    "CloseCard" to "close",
    "ReopenCard" to "reopen",
    "PostponeCard" to "postpone",
    "TriageCard" to "triage",
    "UnTriageCard" to "untriage",
    "GoldCard" to "gold",
    "UngoldCard" to "ungold",
    "AssignCard" to "assign",
    "SelfAssignCard" to "selfAssign",
    "TagCard" to "tag",
    "WatchCard" to "watch",
    "UnwatchCard" to "unwatch",
    "PinCard" to "pin",
    "UnpinCard" to "unpin",
    "MoveCard" to "move",
    "DeleteCardImage" to "deleteImage",
    "ListCardReactions" to "listForCard",
    "CreateCardReaction" to "createForCard",
    "DeleteCardReaction" to "deleteForCard",
    "ListCommentReactions" to "listForComment",
    "CreateCommentReaction" to "createForComment",
    "DeleteCommentReaction" to "deleteForComment",
    "ReadNotification" to "read",
    "UnreadNotification" to "unread",
    "BulkReadNotifications" to "bulkRead",
    "GetNotificationTray" to "tray",
    "CreateDirectUpload" to "createDirect",
    "ActivateWebhook" to "activate",
    "CreateSession" to "create",
    "RedeemMagicLink" to "redeemMagicLink",
    "DestroySession" to "destroy",
    "CompleteSignup" to "completeSignup",
    "CompleteJoin" to "completeJoin",
    "RegisterDevice" to "register",
    "UnregisterDevice" to "unregister",
)

/**
 * Maps OpenAPI schema names to friendly Kotlin type names.
 */
val TYPE_ALIASES = mapOf(
    "Board" to "Board",
    "Column" to "Column",
    "Card" to "Card",
    "Comment" to "Comment",
    "Step" to "Step",
    "Reaction" to "Reaction",
    "Notification" to "Notification",
    "NotificationTray" to "NotificationTray",
    "Tag" to "Tag",
    "User" to "User",
    "Pin" to "Pin",
    "Webhook" to "Webhook",
    "Activity" to "Activity",
    "BoardAccesses" to "BoardAccesses",
    "DataExport" to "DataExport",
    "WebhookDelivery" to "WebhookDelivery",
    "Identity" to "Identity",
    "PendingAuthentication" to "PendingAuthentication",
    "SessionAuthorization" to "SessionAuthorization",
    "DeviceRegistration" to "DeviceRegistration",
    "DirectUpload" to "DirectUpload",
)

/**
 * Simple resource names (lowercase) -- when a method name strips a verb prefix
 * and what's left is one of these, the method is just the verb (e.g., "list", "get").
 */
val SIMPLE_RESOURCES = setOf(
    "board", "boards",
    "column", "columns",
    "card", "cards",
    "comment", "comments",
    "step", "steps",
    "reaction", "reactions",
    "notification", "notifications",
    "tag", "tags",
    "user", "users",
    "pin", "pins",
    "upload", "uploads",
    "webhook", "webhooks",
    "session", "sessions",
    "device", "devices",
    "identity",
    "cardimage",
    "cardreaction", "cardreactions",
    "commentreaction", "commentreactions",
    "directupload",
    "magiclink",
    "notificationtray",
    "signup",
    "deviceregistration",
)
