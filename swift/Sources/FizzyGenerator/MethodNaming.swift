import Foundation

// MARK: - Verb Patterns

/// Ordered list of verb prefixes for extracting method names from operationIds.
let verbPatterns: [(prefix: String, method: String)] = [
    ("Subscribe", "subscribe"),
    ("Unsubscribe", "unsubscribe"),
    ("List", "list"),
    ("Get", "get"),
    ("Create", "create"),
    ("Update", "update"),
    ("Delete", "delete"),
    ("Trash", "trash"),
    ("Archive", "archive"),
    ("Unarchive", "unarchive"),
    ("Complete", "complete"),
    ("Uncomplete", "uncomplete"),
    ("Enable", "enable"),
    ("Disable", "disable"),
    ("Reposition", "reposition"),
    ("Move", "move"),
    ("Clone", "clone"),
    ("Set", "set"),
    ("Pin", "pin"),
    ("Unpin", "unpin"),
    ("Close", "close"),
    ("Reopen", "reopen"),
    ("Postpone", "postpone"),
    ("Triage", "triage"),
    ("Gold", "gold"),
    ("Assign", "assign"),
    ("Tag", "tag"),
    ("Watch", "watch"),
    ("Unwatch", "unwatch"),
    ("Read", "read"),
    ("Unread", "unread"),
    ("Bulk", "bulk"),
    ("Activate", "activate"),
    ("Deactivate", "deactivate"),
    ("Register", "register"),
    ("Unregister", "unregister"),
    ("Redeem", "redeem"),
    ("Destroy", "destroy"),
    ("SelfAssign", "selfAssign"),
    ("Search", "search"),
]

// MARK: - Method Name Overrides

/// Explicit overrides for method name generation.
let methodNameOverrides: [String: String] = [
    "GetMyIdentity": "me",
    "CloseCard": "close",
    "ReopenCard": "reopen",
    "PostponeCard": "postpone",
    "TriageCard": "triage",
    "UnTriageCard": "untriage",
    "GoldCard": "gold",
    "UngoldCard": "ungold",
    "AssignCard": "assign",
    "SelfAssignCard": "selfAssign",
    "TagCard": "tag",
    "WatchCard": "watch",
    "UnwatchCard": "unwatch",
    "PinCard": "pin",
    "UnpinCard": "unpin",
    "MoveCard": "move",
    "DeleteCardImage": "deleteImage",
    "ListCardReactions": "listForCard",
    "CreateCardReaction": "createForCard",
    "DeleteCardReaction": "deleteForCard",
    "ListCommentReactions": "listForComment",
    "CreateCommentReaction": "createForComment",
    "DeleteCommentReaction": "deleteForComment",
    "ReadNotification": "read",
    "UnreadNotification": "unread",
    "BulkReadNotifications": "bulkRead",
    "GetNotificationTray": "tray",
    "CreateDirectUpload": "createDirect",
    "ActivateWebhook": "activate",
    "CreateSession": "create",
    "RedeemMagicLink": "redeemMagicLink",
    "DestroySession": "destroy",
    "CompleteSignup": "completeSignup",
    "CompleteJoin": "completeJoin",
    "RegisterDevice": "register",
    "UnregisterDevice": "unregister",
    "DeactivateUser": "deactivate",
    "CreateStep": "create",
    "GetStep": "get",
    "UpdateStep": "update",
    "DeleteStep": "delete",
]

// MARK: - Simple Resources

/// Resource names that are considered "simple" (verb alone suffices as method name).
private let simpleResources: Set<String> = [
    "board", "boards",
    "card", "cards",
    "column", "columns",
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
    "notificationtray",
    "directupload",
    "magiclink",
    "signup",
    "cardimage",
    "cardreaction", "commentreaction",
]

/// Extracts the method name for an operationId.
func extractMethodName(_ operationId: String) -> String {
    if let override = methodNameOverrides[operationId] {
        return override
    }

    for (prefix, method) in verbPatterns {
        if operationId.hasPrefix(prefix) {
            let remainder = String(operationId.dropFirst(prefix.count))
            if remainder.isEmpty { return method }
            let resource = lowercaseFirst(remainder)
            if simpleResources.contains(resource.lowercased()) { return method }
            return method == "get" ? lowercaseFirst(remainder) : method + remainder
        }
    }

    return lowercaseFirst(operationId)
}
