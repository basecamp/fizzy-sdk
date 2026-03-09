# Fizzy SDK → Rails API Surface Communique

The SDK spec has been expanded from 70 to 102 operations with full conformance coverage across Go, TypeScript, Ruby, Swift, and Kotlin. This document captures what the Rails app needs to match, verified against the Rails source.

---

## Response shape changes already aligned with Rails

These shape changes were made to match what Rails actually returns. No Rails changes needed.

### UserSummary eliminated — full User everywhere

The SDK now expects the full `_user.json.jbuilder` shape (`{id, name, role, active, email_address, avatar_url, created_at, url}`) in all embedded positions: `Board.creator`, `Card.creator`, `Card.assignees[]`, `Comment.creator`, `Reaction.reacter`, `Notification.creator`. Rails already renders the full partial everywhere — **no change needed**.

Note: `email_address` comes from `user.identity&.email_address` — system users with no identity will have `null`. The SDK marks this field optional.

### BoardSummary and ColumnSummary eliminated

`Card.board` and `Card.column` now expect full Board/Column shapes. Rails card partial already renders `json.partial! "boards/board"` and `json.partial! "columns/column"` — **no change needed**.

### Column.color is Object {name, value}

Rails `_column.json.jbuilder` serializes `color` via `json.(column, :color)` which implicitly serializes the `Color = Struct.new(:name, :value)` as `{"name": "Blue", "value": "var(--color-card-default)"}` — **already correct**.

### Tag.name → Tag.title

Rails `_tag.json.jbuilder` already returns `title` (not `name`), plus `created_at` and `url`. **Already aligned**.

Note: `url` is a cards index URL filtered to that tag (`cards_url(tag_ids: [tag])`), not a tag show URL.

### Account: slug, created_at added

Rails `_account.json.jbuilder` already returns `{id, name, slug, created_at}`. The `user` field is added at the identity level (`my/identities/show.json.jbuilder`), not in the account partial itself. **Already aligned**.

### ListPins returns Card[]

Rails `my/pins/index.json.jbuilder` already returns `json.array! @pins { json.partial! "cards/card", card: pin.card }` — flat card array. **Already aligned**.

### All IDs are strings

Rails returns string IDs via `to_param` — **no change needed**.

---

## Shape discrepancies requiring Rails attention

### Card.has_more_assignees, comments_url, reactions_url

Rails card partial includes `has_more_assignees`, `comments_url`, and `reactions_url` fields. The SDK spec doesn't include these. Low priority but worth noting for completeness.

### Card.description_html

Rails card partial returns both `description` (plain text) and `description_html` (HTML). SDK spec only has `description`. Consider adding `description_html` to the spec.

### Steps index: no standalone endpoint

The SDK spec defines `ListSteps` as `GET /{acct}/cards/{number}/steps.json`. Rails has no `steps/index.json.jbuilder` — steps are embedded inline in `cards/show.json.jbuilder` only. Individual step CRUD does have JSON responses.

**Either:** (a) Add a steps index JSON endpoint to Rails, or (b) remove `ListSteps` from the SDK spec and document that steps come from the card show response.

---

## New endpoints: confirmed HTML/Turbo-only in Rails

All of these routes exist in Rails but serve **only HTML or Turbo Stream responses**. Each needs a `respond_to { |format| format.json { head :ok } }` (or appropriate JSON body) added.

### Void-response endpoints (just need `head :ok` / `head :no_content`)

| Operation | Controller | Method | Path |
|-----------|-----------|--------|------|
| PublishBoard | `Boards::PublicationsController#create` | POST | `/{acct}/boards/{id}/publication.json` |
| UnpublishBoard | `Boards::PublicationsController#destroy` | DELETE | `/{acct}/boards/{id}/publication.json` |
| UpdateBoardInvolvement | `Boards::InvolvementsController#update` | PATCH | `/{acct}/boards/{id}/involvement.json` |
| UpdateBoardEntropy | `Boards::EntropiesController#update` | PATCH | `/{acct}/boards/{id}/entropy.json` |
| UpdateAccountEntropy | `Account::EntropiesController#update` | PATCH | `/{acct}/account/entropy.json` |
| MoveColumnLeft | `Columns::LeftPositionsController#create` | POST | `/{acct}/columns/{id}/left_position.json` |
| MoveColumnRight | `Columns::RightPositionsController#create` | POST | `/{acct}/columns/{id}/right_position.json` |
| MarkCardRead | `Cards::ReadingsController#create` | POST | `/{acct}/cards/{number}/reading.json` |
| MarkCardUnread | `Cards::ReadingsController#destroy` | DELETE | `/{acct}/cards/{number}/reading.json` |
| PublishCard | `Cards::PublishesController#create` | POST | `/{acct}/cards/{number}/publish.json` |
| UpdateUserRole | `Users::RolesController#update` | PATCH | `/{acct}/users/{id}/role.json` |
| DeleteUserAvatar | `Users::AvatarsController#destroy` | DELETE | `/{acct}/users/{id}/avatar` |
| UpdateAccountSettings | `Account::SettingsController#update` | PATCH | `/{acct}/account/settings.json` |
| UpdateNotificationSettings | `Notifications::SettingsController#update` | PATCH | `/{acct}/notifications/settings.json` |
| ResetJoinCode | `Account::JoinCodesController#destroy` | DELETE | `/{acct}/account/join_code.json` |
| UpdateJoinCode | `Account::JoinCodesController#update` | PATCH | `/{acct}/account/join_code.json` |
| CreatePushSubscription | `Users::PushSubscriptionsController#create` | POST | `/{acct}/users/{id}/push_subscriptions.json` |
| DeletePushSubscription | `Users::PushSubscriptionsController#destroy` | DELETE | `/{acct}/users/{id}/push_subscriptions/{subId}` |

### Endpoints needing JSON views (return data)

| Operation | Controller | Path | Expected response |
|-----------|-----------|------|-------------------|
| GetAccountSettings | `Account::SettingsController#show` | GET `/{acct}/account/settings.json` | `{name}` |
| GetJoinCode | `Account::JoinCodesController#show` | GET `/{acct}/account/join_code.json` | `{code, url, usage_limit?}` |
| GetNotificationSettings | `Notifications::SettingsController#show` | GET `/{acct}/notifications/settings.json` | `{bundle_email_frequency}` |
| ListStreamCards | `Boards::Columns::StreamsController#show` | GET `/{acct}/boards/{id}/columns/stream.json` | `Card[]` (paginated) |
| ListPostponedCards | `Boards::Columns::NotNowsController#show` | GET `/{acct}/boards/{id}/columns/not_now.json` | `Card[]` (paginated) |
| ListClosedCards | `Boards::Columns::ClosedsController#show` | GET `/{acct}/boards/{id}/columns/closed.json` | `Card[]` (paginated) |
| SearchCards | `SearchesController#show` | GET `/{acct}/search.json?q=...` | `Card[]` (paginated) |
| CreateAccountExport | `Account::ExportsController#create` | POST `/{acct}/account/exports.json` | `{id, status, created_at, download_url?}` |
| GetAccountExport | `Account::ExportsController#show` | GET `/{acct}/account/exports/{id}` | `{id, status, created_at, download_url?}` |

### Access tokens (partial JSON exists)

| Operation | Path | Notes |
|-----------|------|-------|
| ListAccessTokens | GET `/my/access_tokens.json` | **Needs JSON index view** — currently HTML only |
| CreateAccessToken | POST `/my/access_tokens.json` | Has inline JSON (`{token, description, permission}`) — **needs `id` and `created_at` added** |
| DeleteAccessToken | DELETE `/my/access_tokens/{id}` | Needs `format.json { head :no_content }` |

---

## Input field names (SDK sends these — Rails must `permit` them)

| Operation | Field SDK sends | Verify `params.permit` |
|-----------|----------------|----------------------|
| AssignCard | `assignee_id` | Was `user_id` in some references |
| TagCard | `tag_title` | Was `name` in some references |
| UpdateUserRole | `role` | String: "member" or "admin" |
| UpdateBoardInvolvement | `involvement` | String |
| UpdateBoardEntropy | `auto_postpone_period` | Integer |
| UpdateAccountEntropy | `auto_postpone_period` | Integer |
| UpdateAccountSettings | `name` | String |
| UpdateNotificationSettings | `bundle_email_frequency` | String |
| UpdateJoinCode | `usage_limit` | Integer |
| CreatePushSubscription | `endpoint`, `p256dh_key`, `auth_key` | All strings |
| CreateBoard/UpdateBoard | `public_description`, `auto_postpone_period` | New optional fields |
| UpdateBoard | `user_ids` | Array of strings |

---

## Idempotency contract

The SDK retries these operations on 503/5xx (naturally idempotent — calling twice has the same effect). Rails should ensure they're truly safe to replay:

- `MarkCardRead` (POST) / `MarkCardUnread` (DELETE) — toggle read state
- `MoveColumnLeft` / `MoveColumnRight` (POST) — positional, already-leftmost is a no-op
- `PublishBoard` (POST) / `UnpublishBoard` (DELETE) — toggle publish state
- `CloseCard`, `PostponeCard`, `GoldCard`, `PinCard`, `WatchCard`, `TriageCard` (POST)
- `ReopenCard` (DELETE) — reopen a closed card
- `ActivateWebhook` (POST)
- `ReadNotification` (POST)

The SDK does **not** retry: `CreateCard`, `CreateBoard`, `CreateComment`, `CreateStep`, `CreateWebhook`, `AssignCard`, `TagCard`, `PublishCard`, `CreateSession`, `CreateAccessToken`, `CreatePushSubscription`, `CreateAccountExport`.

---

## Priority order

1. **Shape discrepancy decisions** — Card.tags (strings vs objects), ListSteps (standalone vs embedded)
2. **Void-response JSON paths** — 18 controllers need `format.json { head :ok }`, low effort
3. **Data-returning JSON views** — 9 endpoints need jbuilder templates
4. **Access token JSON index** — new template needed
