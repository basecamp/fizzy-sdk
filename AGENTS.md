# Fizzy SDK -- Agent Instructions

## Hard Rules

1. **Never hand-write API methods.** All operations are generated from the Smithy spec.
2. **Never construct URL paths manually.** Use the generated route table.
3. **Every new operation needs tests.** Unit tests per language + conformance tests.
4. **Run `make check` before committing.** All checks must pass.

## Pipeline

```
Smithy spec -> OpenAPI -> Behavior Model -> Per-language generators -> SDK code
```

## Anti-Patterns

- Editing `openapi.json` directly (it is generated from Smithy)
- Adding API methods without updating the Smithy spec
- Skipping conformance tests for behavioral changes
- Using `fmt.Sprintf` or template literals for API paths

## Development Workflow

1. Review upstream Fizzy API sources:
   - [`docs/api/README.md`](https://github.com/basecamp/fizzy/blob/main/docs/api/README.md)
   - [`docs/api/sections/`](https://github.com/basecamp/fizzy/tree/main/docs/api/sections)
   - [`config/routes.rb`](https://github.com/basecamp/fizzy/blob/main/config/routes.rb)
   - [`app/controllers/`](https://github.com/basecamp/fizzy/tree/main/app/controllers)
   - [`app/views/`](https://github.com/basecamp/fizzy/tree/main/app/views)
   - [`app/models/`](https://github.com/basecamp/fizzy/tree/main/app/models)
2. Edit the Smithy spec in `spec/`
3. Run `make smithy-build` to regenerate OpenAPI
4. Run per-language generators: `make {lang}-generate-services`
5. Add/update tests
6. Run `make check`
7. Commit

## Upstream Reference Sources

When syncing the SDK spec to upstream Fizzy changes, treat these as the primary references:

- **API docs** — [`docs/api/README.md`](https://github.com/basecamp/fizzy/blob/main/docs/api/README.md)
- **API section docs** — [`docs/api/sections/`](https://github.com/basecamp/fizzy/tree/main/docs/api/sections)
- **Routes** — [`config/routes.rb`](https://github.com/basecamp/fizzy/blob/main/config/routes.rb)
- **Controllers** — [`app/controllers/`](https://github.com/basecamp/fizzy/tree/main/app/controllers)
- **Views / JSON rendering** — [`app/views/`](https://github.com/basecamp/fizzy/tree/main/app/views)
- **Relevant models** — [`app/models/`](https://github.com/basecamp/fizzy/tree/main/app/models)

The SDK generation pipeline still starts from Smithy, but Smithy should be kept aligned with these upstream sources.

## Auth Model

Fizzy uses **two auth strategies** (no OAuth):

- **BearerAuth** — `Authorization: Bearer <token>` for CLI/API access tokens
- **CookieAuth** — `Cookie: session_token=<value>` for session-based auth (mobile/web)
- **MagicLinkFlow** — orchestrates passwordless login: `CreateSession` → `RedeemMagicLink`

## API Surface Inventory

111 operations across the current Smithy-defined API surface:

| Area | Operations |
|---------|-----------|
| Identity | GetMyIdentity |
| Access Tokens | ListAccessTokens, CreateAccessToken, DeleteAccessToken |
| Account | GetAccountSettings, UpdateAccountSettings, GetJoinCode, UpdateJoinCode, ResetJoinCode, UpdateAccountEntropy, CreateAccountExport, GetAccountExport |
| Boards | ListBoards, CreateBoard, GetBoard, ListBoardAccesses, UpdateBoard, DeleteBoard, PublishBoard, UnpublishBoard, UpdateBoardInvolvement, UpdateBoardEntropy, ListStreamCards, ListPostponedCards, ListClosedCards |
| Columns | ListColumns, CreateColumn, GetColumn, UpdateColumn, DeleteColumn, MoveColumnLeft, MoveColumnRight |
| Cards | ListCards, ListColumnCards, CreateCard, GetCard, UpdateCard, DeleteCard, CloseCard, ReopenCard, PostponeCard, TriageCard, UnTriageCard, GoldCard, UngoldCard, AssignCard, SelfAssignCard, TagCard, WatchCard, UnwatchCard, PinCard, UnpinCard, MoveCard, DeleteCardImage, MarkCardRead, MarkCardUnread, PublishCard |
| Comments | ListComments, CreateComment, GetComment, UpdateComment, DeleteComment |
| Steps | ListSteps, CreateStep, GetStep, UpdateStep, DeleteStep |
| Reactions | ListCardReactions, CreateCardReaction, DeleteCardReaction, ListCommentReactions, CreateCommentReaction, DeleteCommentReaction |
| Notifications | ListNotifications, ReadNotification, UnreadNotification, BulkReadNotifications, GetNotificationTray, GetNotificationSettings, UpdateNotificationSettings |
| Search | SearchCards |
| Activities | ListActivities |
| Tags | ListTags |
| Users | ListUsers, GetUser, UpdateUser, DeactivateUser, RequestEmailAddressChange, ConfirmEmailAddressChange, CreateUserDataExport, GetUserDataExport, UpdateUserRole, DeleteUserAvatar, CreatePushSubscription, DeletePushSubscription |
| Pins | ListPins |
| Uploads | CreateDirectUpload |
| Webhooks | ListWebhooks, CreateWebhook, GetWebhook, UpdateWebhook, DeleteWebhook, ActivateWebhook, ListWebhookDeliveries |
| Sessions | CreateSession, RedeemMagicLink, DestroySession, CompleteSignup, CompleteJoin |
| Devices | RegisterDevice, UnregisterDevice |
