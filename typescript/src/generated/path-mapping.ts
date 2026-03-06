/**
 * Maps HTTP method + path to OpenAPI operationId.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

export const PATH_TO_OPERATION: Record<string, string> = {
  // Boards
  "GET:/{accountId}/boards.json": "ListBoards",
  "POST:/{accountId}/boards.json": "CreateBoard",
  "DELETE:/{accountId}/boards/{boardId}": "DeleteBoard",
  "GET:/{accountId}/boards/{boardId}": "GetBoard",
  "PATCH:/{accountId}/boards/{boardId}": "UpdateBoard",
  "GET:/{accountId}/boards/{boardId}/columns.json": "ListColumns",
  "POST:/{accountId}/boards/{boardId}/columns.json": "CreateColumn",
  "GET:/{accountId}/boards/{boardId}/columns/{columnId}": "GetColumn",
  "PATCH:/{accountId}/boards/{boardId}/columns/{columnId}": "UpdateColumn",
  "GET:/{accountId}/boards/{boardId}/webhooks.json": "ListWebhooks",
  "POST:/{accountId}/boards/{boardId}/webhooks.json": "CreateWebhook",
  "DELETE:/{accountId}/boards/{boardId}/webhooks/{webhookId}": "DeleteWebhook",
  "GET:/{accountId}/boards/{boardId}/webhooks/{webhookId}": "GetWebhook",
  "PATCH:/{accountId}/boards/{boardId}/webhooks/{webhookId}": "UpdateWebhook",
  "POST:/{accountId}/boards/{boardId}/webhooks/{webhookId}/activation.json": "ActivateWebhook",

  // Cards
  "GET:/{accountId}/cards.json": "ListCards",
  "POST:/{accountId}/cards.json": "CreateCard",
  "DELETE:/{accountId}/cards/{cardNumber}": "DeleteCard",
  "GET:/{accountId}/cards/{cardNumber}": "GetCard",
  "PATCH:/{accountId}/cards/{cardNumber}": "UpdateCard",
  "POST:/{accountId}/cards/{cardNumber}/assignments.json": "AssignCard",
  "PATCH:/{accountId}/cards/{cardNumber}/board.json": "MoveCard",
  "DELETE:/{accountId}/cards/{cardNumber}/closure.json": "ReopenCard",
  "POST:/{accountId}/cards/{cardNumber}/closure.json": "CloseCard",
  "DELETE:/{accountId}/cards/{cardNumber}/goldness.json": "UngoldCard",
  "POST:/{accountId}/cards/{cardNumber}/goldness.json": "GoldCard",
  "DELETE:/{accountId}/cards/{cardNumber}/image.json": "DeleteCardImage",
  "POST:/{accountId}/cards/{cardNumber}/not_now.json": "PostponeCard",
  "DELETE:/{accountId}/cards/{cardNumber}/pin.json": "UnpinCard",
  "POST:/{accountId}/cards/{cardNumber}/pin.json": "PinCard",
  "POST:/{accountId}/cards/{cardNumber}/self_assignment.json": "SelfAssignCard",
  "POST:/{accountId}/cards/{cardNumber}/taggings.json": "TagCard",
  "DELETE:/{accountId}/cards/{cardNumber}/triage.json": "UnTriageCard",
  "POST:/{accountId}/cards/{cardNumber}/triage.json": "TriageCard",
  "DELETE:/{accountId}/cards/{cardNumber}/watch.json": "UnwatchCard",
  "POST:/{accountId}/cards/{cardNumber}/watch.json": "WatchCard",

  // Comments
  "GET:/{accountId}/cards/{cardNumber}/comments.json": "ListComments",
  "POST:/{accountId}/cards/{cardNumber}/comments.json": "CreateComment",
  "DELETE:/{accountId}/cards/{cardNumber}/comments/{commentId}": "DeleteComment",
  "GET:/{accountId}/cards/{cardNumber}/comments/{commentId}": "GetComment",
  "PATCH:/{accountId}/cards/{cardNumber}/comments/{commentId}": "UpdateComment",
  "GET:/{accountId}/cards/{cardNumber}/comments/{commentId}/reactions.json": "ListCommentReactions",
  "POST:/{accountId}/cards/{cardNumber}/comments/{commentId}/reactions.json": "CreateCommentReaction",
  "DELETE:/{accountId}/cards/{cardNumber}/comments/{commentId}/reactions/{reactionId}": "DeleteCommentReaction",

  // Card Reactions
  "GET:/{accountId}/cards/{cardNumber}/reactions.json": "ListCardReactions",
  "POST:/{accountId}/cards/{cardNumber}/reactions.json": "CreateCardReaction",
  "DELETE:/{accountId}/cards/{cardNumber}/reactions/{reactionId}": "DeleteCardReaction",

  // Steps
  "POST:/{accountId}/cards/{cardNumber}/steps.json": "CreateStep",
  "DELETE:/{accountId}/cards/{cardNumber}/steps/{stepId}": "DeleteStep",
  "GET:/{accountId}/cards/{cardNumber}/steps/{stepId}": "GetStep",
  "PATCH:/{accountId}/cards/{cardNumber}/steps/{stepId}": "UpdateStep",

  // Devices
  "POST:/{accountId}/devices": "RegisterDevice",
  "DELETE:/{accountId}/devices/{deviceToken}": "UnregisterDevice",

  // Other
  "GET:/{accountId}/my/identity.json": "GetMyIdentity",
  "POST:/{accountId}/rails/active_storage/direct_uploads": "CreateDirectUpload",
  "DELETE:/{accountId}/session.json": "DestroySession",
  "POST:/{accountId}/session.json": "CreateSession",
  "POST:/{accountId}/session/magic_link.json": "RedeemMagicLink",
  "POST:/{accountId}/signup/completion.json": "CompleteSignup",

  // Pins
  "GET:/{accountId}/my/pins.json": "ListPins",

  // Notifications
  "GET:/{accountId}/notifications.json": "ListNotifications",
  "DELETE:/{accountId}/notifications/{notificationId}/reading.json": "UnreadNotification",
  "POST:/{accountId}/notifications/{notificationId}/reading.json": "ReadNotification",
  "POST:/{accountId}/notifications/bulk_reading.json": "BulkReadNotifications",
  "GET:/{accountId}/notifications/tray.json": "GetNotificationTray",

  // Tags
  "GET:/{accountId}/tags.json": "ListTags",

  // Users
  "GET:/{accountId}/users.json": "ListUsers",
  "DELETE:/{accountId}/users/{userId}": "DeactivateUser",
  "GET:/{accountId}/users/{userId}": "GetUser",
  "PATCH:/{accountId}/users/{userId}": "UpdateUser",
};
