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

1. Edit the Smithy spec in `spec/`
2. Run `make smithy-build` to regenerate OpenAPI
3. Run per-language generators: `make {lang}-generate-services`
4. Add/update tests
5. Run `make check`
6. Commit

## Auth Model

Fizzy uses **two auth strategies** (no OAuth):

- **BearerAuth** — `Authorization: Bearer <token>` for CLI/API access tokens
- **CookieAuth** — `Cookie: session_token=<value>` for session-based auth (mobile/web)
- **MagicLinkFlow** — orchestrates passwordless login: `CreateSession` → `RedeemMagicLink`

## Service Inventory

70 operations across 15 services:

| Service | Operations |
|---------|-----------|
| Identity | GetMyIdentity |
| Boards | ListBoards, CreateBoard, GetBoard, UpdateBoard, DeleteBoard |
| Columns | ListColumns, CreateColumn, GetColumn, UpdateColumn |
| Cards | ListCards, CreateCard, GetCard, UpdateCard, DeleteCard, CloseCard, ReopenCard, PostponeCard, TriageCard, UnTriageCard, GoldCard, UngoldCard, AssignCard, SelfAssignCard, TagCard, WatchCard, UnwatchCard, PinCard, UnpinCard, MoveCard, DeleteCardImage |
| Comments | ListComments, CreateComment, GetComment, UpdateComment, DeleteComment |
| Steps | CreateStep, GetStep, UpdateStep, DeleteStep |
| Reactions | ListCardReactions, CreateCardReaction, DeleteCardReaction, ListCommentReactions, CreateCommentReaction, DeleteCommentReaction |
| Notifications | ListNotifications, ReadNotification, UnreadNotification, BulkReadNotifications, GetNotificationTray |
| Tags | ListTags |
| Users | ListUsers, GetUser, UpdateUser, DeactivateUser |
| Pins | ListPins |
| Uploads | CreateDirectUpload |
| Webhooks | ListWebhooks, CreateWebhook, GetWebhook, UpdateWebhook, DeleteWebhook, ActivateWebhook |
| Sessions | CreateSession, RedeemMagicLink, DestroySession, CompleteSignup |
| Devices | RegisterDevice, UnregisterDevice |
