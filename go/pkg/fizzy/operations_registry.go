// Code generated from openapi.json — DO NOT EDIT.
package fizzy

// OperationRegistry maps every OpenAPI operationId to its Go service method.
// The drift check script (scripts/check-service-drift.sh) verifies this
// registry stays in sync with openapi.json.
//
// To update: run 'go run ./cmd/generate-services/' from the go directory.
var OperationRegistry = map[string]string{
	// Boards
	"CreateBoard": "BoardsService.Create",
	"DeleteBoard": "BoardsService.Delete",
	"GetBoard": "BoardsService.Get",
	"ListBoards": "BoardsService.List",
	"UpdateBoard": "BoardsService.Update",

	// Cards
	"AssignCard": "CardsService.Assign",
	"CloseCard": "CardsService.Close",
	"CreateCard": "CardsService.Create",
	"DeleteCard": "CardsService.Delete",
	"DeleteCardImage": "CardsService.DeleteImage",
	"GetCard": "CardsService.Get",
	"GoldCard": "CardsService.Gold",
	"ListCards": "CardsService.List",
	"MoveCard": "CardsService.Move",
	"PinCard": "CardsService.Pin",
	"PostponeCard": "CardsService.Postpone",
	"ReopenCard": "CardsService.Reopen",
	"SelfAssignCard": "CardsService.SelfAssign",
	"TagCard": "CardsService.Tag",
	"TriageCard": "CardsService.Triage",
	"UnTriageCard": "CardsService.UnTriage",
	"UngoldCard": "CardsService.Ungold",
	"UnpinCard": "CardsService.Unpin",
	"UnwatchCard": "CardsService.Unwatch",
	"UpdateCard": "CardsService.Update",
	"WatchCard": "CardsService.Watch",

	// Columns
	"CreateColumn": "ColumnsService.Create",
	"DeleteColumn": "ColumnsService.Delete",
	"GetColumn": "ColumnsService.Get",
	"ListColumns": "ColumnsService.List",
	"UpdateColumn": "ColumnsService.Update",

	// Comments
	"CreateComment": "CommentsService.Create",
	"DeleteComment": "CommentsService.Delete",
	"GetComment": "CommentsService.Get",
	"ListComments": "CommentsService.List",
	"UpdateComment": "CommentsService.Update",

	// Devices
	"RegisterDevice": "DevicesService.Register",
	"UnregisterDevice": "DevicesService.Unregister",

	// Identity
	"GetMyIdentity": "IdentityService.GetMyIdentity",

	// Notifications
	"BulkReadNotifications": "NotificationsService.BulkRead",
	"GetNotificationTray": "NotificationsService.GetTray",
	"ListNotifications": "NotificationsService.List",
	"ReadNotification": "NotificationsService.Read",
	"UnreadNotification": "NotificationsService.Unread",

	// Pins
	"ListPins": "PinsService.List",

	// Reactions
	"CreateCardReaction": "ReactionsService.CreateCard",
	"CreateCommentReaction": "ReactionsService.CreateComment",
	"DeleteCardReaction": "ReactionsService.DeleteCard",
	"DeleteCommentReaction": "ReactionsService.DeleteComment",
	"ListCardReactions": "ReactionsService.ListCard",
	"ListCommentReactions": "ReactionsService.ListComment",

	// Sessions
	"CompleteSignup": "SessionsService.CompleteSignup",
	"CreateSession": "SessionsService.Create",
	"DestroySession": "SessionsService.Destroy",
	"RedeemMagicLink": "SessionsService.RedeemMagicLink",

	// Steps
	"CreateStep": "StepsService.Create",
	"DeleteStep": "StepsService.Delete",
	"GetStep": "StepsService.Get",
	"UpdateStep": "StepsService.Update",

	// Tags
	"ListTags": "TagsService.List",

	// Uploads
	"CreateDirectUpload": "UploadsService.CreateDirectUpload",

	// Users
	"DeactivateUser": "UsersService.Deactivate",
	"GetUser": "UsersService.Get",
	"ListUsers": "UsersService.List",
	"UpdateUser": "UsersService.Update",

	// Webhooks
	"ActivateWebhook": "WebhooksService.Activate",
	"CreateWebhook": "WebhooksService.Create",
	"DeleteWebhook": "WebhooksService.Delete",
	"GetWebhook": "WebhooksService.Get",
	"ListWebhooks": "WebhooksService.List",
	"UpdateWebhook": "WebhooksService.Update",
}
