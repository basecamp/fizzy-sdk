package fizzy

// OperationRegistry maps every OpenAPI operationId to its Go service method.
// The drift check script (scripts/check-service-drift.sh) verifies this
// registry stays in sync with openapi.json.
//
// When adding a new API operation: add the operationId here and implement
// the corresponding service method.
var OperationRegistry = map[string]string{
	// Boards
	"ListBoards":  "BoardsService.List",
	"CreateBoard": "BoardsService.Create",
	"GetBoard":    "BoardsService.Get",
	"UpdateBoard": "BoardsService.Update",
	"DeleteBoard": "BoardsService.Delete",

	// Cards
	"ListCards":      "CardsService.List",
	"CreateCard":     "CardsService.Create",
	"GetCard":        "CardsService.Get",
	"UpdateCard":     "CardsService.Update",
	"DeleteCard":     "CardsService.Delete",
	"CloseCard":      "CardsService.Close",
	"ReopenCard":     "CardsService.Reopen",
	"PostponeCard":   "CardsService.Postpone",
	"TriageCard":     "CardsService.Triage",
	"UnTriageCard":   "CardsService.UnTriage",
	"GoldCard":       "CardsService.Gold",
	"UngoldCard":     "CardsService.Ungold",
	"AssignCard":     "CardsService.Assign",
	"SelfAssignCard": "CardsService.SelfAssign",
	"TagCard":        "CardsService.Tag",
	"WatchCard":      "CardsService.Watch",
	"UnwatchCard":    "CardsService.Unwatch",
	"PinCard":        "CardsService.Pin",
	"UnpinCard":      "CardsService.Unpin",
	"MoveCard":       "CardsService.Move",
	"DeleteCardImage": "CardsService.DeleteImage",

	// Columns
	"ListColumns":  "ColumnsService.List",
	"CreateColumn": "ColumnsService.Create",
	"GetColumn":    "ColumnsService.Get",
	"UpdateColumn": "ColumnsService.Update",

	// Comments
	"ListComments":  "CommentsService.List",
	"CreateComment": "CommentsService.Create",
	"GetComment":    "CommentsService.Get",
	"UpdateComment": "CommentsService.Update",
	"DeleteComment": "CommentsService.Delete",

	// Devices
	"RegisterDevice":   "DevicesService.Register",
	"UnregisterDevice": "DevicesService.Unregister",

	// Identity
	"GetMyIdentity": "IdentityService.GetMyIdentity",

	// Notifications
	"ListNotifications":    "NotificationsService.List",
	"ReadNotification":     "NotificationsService.Read",
	"UnreadNotification":   "NotificationsService.Unread",
	"BulkReadNotifications": "NotificationsService.BulkRead",
	"GetNotificationTray":  "NotificationsService.GetTray",

	// Pins
	"ListPins": "PinsService.List",

	// Reactions
	"ListCardReactions":     "ReactionsService.ListCard",
	"CreateCardReaction":    "ReactionsService.CreateCard",
	"DeleteCardReaction":    "ReactionsService.DeleteCard",
	"ListCommentReactions":  "ReactionsService.ListComment",
	"CreateCommentReaction": "ReactionsService.CreateComment",
	"DeleteCommentReaction": "ReactionsService.DeleteComment",

	// Sessions
	"CreateSession":   "SessionsService.Create",
	"RedeemMagicLink": "SessionsService.RedeemMagicLink",
	"DestroySession":  "SessionsService.Destroy",
	"CompleteSignup":  "SessionsService.CompleteSignup",

	// Steps
	"CreateStep": "StepsService.Create",
	"GetStep":    "StepsService.Get",
	"UpdateStep": "StepsService.Update",
	"DeleteStep": "StepsService.Delete",

	// Tags
	"ListTags": "TagsService.List",

	// Uploads
	"CreateDirectUpload": "UploadsService.CreateDirectUpload",

	// Users
	"ListUsers":      "UsersService.List",
	"GetUser":        "UsersService.Get",
	"UpdateUser":     "UsersService.Update",
	"DeactivateUser": "UsersService.Deactivate",

	// Webhooks
	"ListWebhooks":    "WebhooksService.List",
	"CreateWebhook":   "WebhooksService.Create",
	"GetWebhook":      "WebhooksService.Get",
	"UpdateWebhook":   "WebhooksService.Update",
	"DeleteWebhook":   "WebhooksService.Delete",
	"ActivateWebhook": "WebhooksService.Activate",
}
