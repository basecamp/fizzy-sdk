// Code generated from openapi.json — DO NOT EDIT.
package fizzy

// OperationRegistry maps every OpenAPI operationId to its Go service method.
// The drift check script (scripts/check-service-drift.sh) verifies this
// registry stays in sync with openapi.json.
//
// To update: run 'go run ./cmd/generate-services/' from the go directory.
var OperationRegistry = map[string]string{
	// AccessTokens
	"CreateAccessToken": "AccessTokensService.Create",
	"DeleteAccessToken": "AccessTokensService.Delete",
	"ListAccessTokens": "AccessTokensService.List",

	// Account
	"CreateAccountExport": "AccountService.CreateExport",
	"GetAccountExport": "AccountService.GetExport",
	"GetAccountSettings": "AccountService.GetSettings",
	"GetJoinCode": "AccountService.GetJoinCode",
	"ResetJoinCode": "AccountService.ResetJoinCode",
	"UpdateAccountEntropy": "AccountService.UpdateEntropy",
	"UpdateAccountSettings": "AccountService.UpdateSettings",
	"UpdateJoinCode": "AccountService.UpdateJoinCode",

	// Boards
	"CreateBoard": "BoardsService.Create",
	"DeleteBoard": "BoardsService.Delete",
	"GetBoard": "BoardsService.Get",
	"ListBoards": "BoardsService.List",
	"ListClosedCards": "BoardsService.ListClosed",
	"ListPostponedCards": "BoardsService.ListPostponed",
	"ListStreamCards": "BoardsService.ListStream",
	"PublishBoard": "BoardsService.Publish",
	"UnpublishBoard": "BoardsService.Unpublish",
	"UpdateBoard": "BoardsService.Update",
	"UpdateBoardEntropy": "BoardsService.UpdateEntropy",
	"UpdateBoardInvolvement": "BoardsService.UpdateInvolvement",

	// Cards
	"AssignCard": "CardsService.Assign",
	"CloseCard": "CardsService.Close",
	"CreateCard": "CardsService.Create",
	"DeleteCard": "CardsService.Delete",
	"DeleteCardImage": "CardsService.DeleteImage",
	"GetCard": "CardsService.Get",
	"GoldCard": "CardsService.Gold",
	"ListCards": "CardsService.List",
	"MarkCardRead": "CardsService.MarkRead",
	"MarkCardUnread": "CardsService.MarkUnread",
	"MoveCard": "CardsService.Move",
	"PinCard": "CardsService.Pin",
	"PostponeCard": "CardsService.Postpone",
	"PublishCard": "CardsService.Publish",
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
	"MoveColumnLeft": "ColumnsService.MoveLeft",
	"MoveColumnRight": "ColumnsService.MoveRight",
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
	"GetNotificationSettings": "NotificationsService.GetSettings",
	"GetNotificationTray": "NotificationsService.GetTray",
	"ListNotifications": "NotificationsService.List",
	"ReadNotification": "NotificationsService.Read",
	"UnreadNotification": "NotificationsService.Unread",
	"UpdateNotificationSettings": "NotificationsService.UpdateSettings",

	// Pins
	"ListPins": "PinsService.List",

	// Reactions
	"CreateCardReaction": "ReactionsService.CreateCard",
	"CreateCommentReaction": "ReactionsService.CreateComment",
	"DeleteCardReaction": "ReactionsService.DeleteCard",
	"DeleteCommentReaction": "ReactionsService.DeleteComment",
	"ListCardReactions": "ReactionsService.ListCard",
	"ListCommentReactions": "ReactionsService.ListComment",

	// Search
	"SearchCards": "SearchService.Search",

	// Sessions
	"CompleteJoin": "SessionsService.CompleteJoin",
	"CompleteSignup": "SessionsService.CompleteSignup",
	"CreateSession": "SessionsService.Create",
	"DestroySession": "SessionsService.Destroy",
	"RedeemMagicLink": "SessionsService.RedeemMagicLink",

	// Steps
	"CreateStep": "StepsService.Create",
	"DeleteStep": "StepsService.Delete",
	"GetStep": "StepsService.Get",
	"ListSteps": "StepsService.List",
	"UpdateStep": "StepsService.Update",

	// Tags
	"ListTags": "TagsService.List",

	// Uploads
	"CreateDirectUpload": "UploadsService.CreateDirectUpload",

	// Users
	"CreatePushSubscription": "UsersService.CreatePushSubscription",
	"DeactivateUser": "UsersService.Deactivate",
	"DeletePushSubscription": "UsersService.DeletePushSubscription",
	"DeleteUserAvatar": "UsersService.DeleteAvatar",
	"GetUser": "UsersService.Get",
	"ListUsers": "UsersService.List",
	"UpdateUser": "UsersService.Update",
	"UpdateUserRole": "UsersService.UpdateRole",

	// Webhooks
	"ActivateWebhook": "WebhooksService.Activate",
	"CreateWebhook": "WebhooksService.Create",
	"DeleteWebhook": "WebhooksService.Delete",
	"GetWebhook": "WebhooksService.Get",
	"ListWebhooks": "WebhooksService.List",
	"UpdateWebhook": "WebhooksService.Update",
}
