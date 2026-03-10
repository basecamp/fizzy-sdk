$version: "2"

namespace fizzy

use aws.protocols#restJson1
use fizzy.traits#fizzyRetry
use fizzy.traits#fizzyPagination
use fizzy.traits#fizzyIdempotent
use fizzy.traits#fizzySensitive

// ═══════════════════════════════════════════════════════════════════════════
// Service
// ═══════════════════════════════════════════════════════════════════════════
//
// Fizzy — card-based project management.
//
// Auth model: Bearer tokens (CLI/API) or Cookie session tokens (mobile/web).
// No OAuth. Magic-link passwordless login for session creation.
//
// Response format: Top-level arrays for list endpoints, top-level objects
// for single-resource endpoints. The smithy-bare-arrays plugin unwraps
// the Smithy wrapper structures in the generated OpenAPI spec.
//
// Card identity: Cards are addressed by `number` (sequential integer per
// account), not by database ID. All nested card resources use cardNumber.

@restJson1
service Fizzy {
    version: "2026-03-01"
    operations: [
        // Identity
        GetMyIdentity

        // Access Tokens
        ListAccessTokens
        CreateAccessToken
        DeleteAccessToken

        // Account
        GetAccountSettings
        UpdateAccountSettings
        GetJoinCode
        UpdateJoinCode
        ResetJoinCode
        UpdateAccountEntropy
        CreateAccountExport
        GetAccountExport

        // Boards
        ListBoards
        CreateBoard
        GetBoard
        UpdateBoard
        DeleteBoard
        PublishBoard
        UnpublishBoard
        UpdateBoardInvolvement
        UpdateBoardEntropy
        ListStreamCards
        ListPostponedCards
        ListClosedCards

        // Columns
        ListColumns
        CreateColumn
        GetColumn
        UpdateColumn
        DeleteColumn
        MoveColumnLeft
        MoveColumnRight

        // Cards
        ListCards
        CreateCard
        GetCard
        UpdateCard
        DeleteCard
        CloseCard
        ReopenCard
        PostponeCard
        TriageCard
        UnTriageCard
        GoldCard
        UngoldCard
        AssignCard
        SelfAssignCard
        TagCard
        WatchCard
        UnwatchCard
        PinCard
        UnpinCard
        MoveCard
        DeleteCardImage
        MarkCardRead
        MarkCardUnread
        PublishCard

        // Comments
        ListComments
        CreateComment
        GetComment
        UpdateComment
        DeleteComment

        // Steps
        ListSteps
        CreateStep
        GetStep
        UpdateStep
        DeleteStep

        // Reactions
        ListCardReactions
        CreateCardReaction
        DeleteCardReaction
        ListCommentReactions
        CreateCommentReaction
        DeleteCommentReaction

        // Notifications
        ListNotifications
        ReadNotification
        UnreadNotification
        BulkReadNotifications
        GetNotificationTray
        GetNotificationSettings
        UpdateNotificationSettings

        // Search
        SearchCards

        // Tags
        ListTags

        // Users
        ListUsers
        GetUser
        UpdateUser
        DeactivateUser
        UpdateUserRole
        DeleteUserAvatar
        CreatePushSubscription
        DeletePushSubscription

        // Pins
        ListPins

        // Uploads
        CreateDirectUpload

        // Webhooks
        ListWebhooks
        CreateWebhook
        GetWebhook
        UpdateWebhook
        DeleteWebhook
        ActivateWebhook

        // Sessions
        CreateSession
        RedeemMagicLink
        DestroySession
        CompleteSignup
        CompleteJoin

        // Devices
        RegisterDevice
        UnregisterDevice
    ]
    errors: [
        NotFoundError
        ValidationError
        RateLimitError
        UnauthorizedError
        ForbiddenError
        BadRequestError
        InternalServerError
    ]
}

// ═══════════════════════════════════════════════════════════════════════════
// Errors
// ═══════════════════════════════════════════════════════════════════════════

@error("client")
@httpError(404)
structure NotFoundError {
    @required
    message: String
}

@error("client")
@httpError(422)
structure ValidationError {
    @required
    message: String
    errors: ValidationErrors
}

list ValidationErrors {
    member: String
}

@error("client")
@httpError(429)
@retryable(throttling: true)
structure RateLimitError {
    @required
    message: String
}

@error("client")
@httpError(401)
structure UnauthorizedError {
    @required
    message: String
}

@error("client")
@httpError(403)
structure ForbiddenError {
    @required
    message: String
}

@error("client")
@httpError(400)
structure BadRequestError {
    @required
    message: String
}

@error("server")
@httpError(500)
@retryable
structure InternalServerError {
    @required
    message: String
}

// ═══════════════════════════════════════════════════════════════════════════
// Common types
// ═══════════════════════════════════════════════════════════════════════════

@sensitive
string EmailAddress

@sensitive
string PersonName

string ISO8601Timestamp

string ISO8601Date

string URL

string BoardId

string ColumnId

integer CardNumber

string CommentId

string StepId

string ReactionId

string NotificationId

string UserId

string TagId

string WebhookId

string AccountId

string DeviceToken

// ═══════════════════════════════════════════════════════════════════════════
// Resource shapes
// ═══════════════════════════════════════════════════════════════════════════

structure Board {
    @required
    id: BoardId
    @required
    name: String
    @required
    all_access: Boolean
    @required
    created_at: ISO8601Timestamp
    auto_postpone_period_in_days: Integer
    @required
    url: URL
    creator: User
}

structure Color {
    @required
    name: String
    @required
    value: String
}

structure Column {
    @required
    id: ColumnId
    @required
    name: String
    color: Color
    @required
    created_at: ISO8601Timestamp
}

structure Card {
    @required
    id: String
    @required
    number: CardNumber
    @required
    title: String
    @required
    status: String
    description: String
    description_html: String
    image_url: URL
    @required
    has_attachments: Boolean
    tags: TagNames
    @required
    closed: Boolean
    @required
    postponed: Boolean
    @required
    golden: Boolean
    last_active_at: ISO8601Timestamp
    @required
    created_at: ISO8601Timestamp
    @required
    url: URL
    board: Board
    column: Column
    creator: User
    assignees: UserList
    has_more_assignees: Boolean
    comments_url: URL
    reactions_url: URL
    steps: StepList
}

list TagNames {
    member: String
}

list StepList {
    member: Step
}

structure User {
    @required
    id: UserId
    @required
    name: PersonName
    @required
    role: String
    @required
    active: Boolean
    @fizzySensitive(category: "pii", redact: true)
    @required
    email_address: EmailAddress
    @required
    created_at: ISO8601Timestamp
    @required
    url: URL
    avatar_url: URL
}

structure Comment {
    @required
    id: CommentId
    @required
    created_at: ISO8601Timestamp
    @required
    updated_at: ISO8601Timestamp
    @required
    body: RichTextBody
    @required
    creator: User
    card: CardRef
    reactions_url: URL
    @required
    url: URL
}

structure RichTextBody {
    @required
    plain_text: String
    @required
    html: String
}

structure CardRef {
    @required
    id: String
    @required
    url: URL
}

structure Step {
    @required
    id: StepId
    @required
    content: String
    @required
    completed: Boolean
}

structure Reaction {
    @required
    id: ReactionId
    @required
    content: String
    @required
    reacter: User
    @required
    url: URL
}

structure Notification {
    @required
    id: NotificationId
    @required
    unread_count: Integer
    @required
    read: Boolean
    read_at: ISO8601Timestamp
    @required
    created_at: ISO8601Timestamp
    @required
    source_type: String
    title: String
    body: String
    @required
    creator: User
    card: NotificationCard
    @required
    url: URL
}

structure NotificationCard {
    @required
    id: String
    @required
    number: CardNumber
    @required
    title: String
    @required
    status: String
    board_name: String
    @required
    closed: Boolean
    @required
    postponed: Boolean
    @required
    url: URL
    column: Column
}

structure Tag {
    @required
    id: TagId
    @required
    title: String
    @required
    created_at: ISO8601Timestamp
    url: URL
}

structure Webhook {
    @required
    id: WebhookId
    @required
    name: String
    @required
    url: URL
    @required
    subscribed_actions: WebhookActions
    @required
    signing_secret: String
    @required
    active: Boolean
    @required
    created_at: ISO8601Timestamp
    @required
    updated_at: ISO8601Timestamp
}

list WebhookActions {
    member: String
}

structure PendingAuthentication {
    @required
    pending_authentication_token: String
}

structure SessionAuthorization {
    @required
    session_token: String
    @required
    requires_signup_completion: Boolean
}

structure DeviceRegistration {
    @required
    token: String
    @required
    platform: String
    name: String
}

structure Identity {
    @required
    id: UserId
    @required
    name: PersonName
    @fizzySensitive(category: "pii", redact: true)
    @required
    email_address: EmailAddress
    @required
    accounts: AccountList
}

structure Account {
    @required
    id: AccountId
    @required
    name: String
    @required
    slug: String
    @required
    created_at: ISO8601Timestamp
    @required
    url: URL
    user: User
}

list AccountList {
    member: Account
}

structure DirectUpload {
    @required
    id: String
    @required
    key: String
    @required
    filename: String
    @required
    content_type: String
    @required
    byte_size: Long
    @required
    checksum: String
    @required
    direct_upload: DirectUploadMetadata
}

structure DirectUploadMetadata {
    @required
    url: URL
    @required
    headers: DirectUploadHeaders
}

structure DirectUploadHeaders {
    @required
    Content_Type: String
    Content_MD5: String
}

structure AccessToken {
    @required
    id: String
    @required
    description: String
    @required
    permission: String
    @required
    created_at: ISO8601Timestamp
    token: String
}

structure NotificationSettings {
    @required
    bundle_email_frequency: String
}

structure AccountSettings {
    @required
    id: AccountId
    @required
    name: String
    @required
    cards_count: Integer
    @required
    created_at: ISO8601Timestamp
    auto_postpone_period_in_days: Integer
}

structure JoinCode {
    @required
    code: String
    @required
    url: URL
    usage_limit: Integer
}

structure AccountExport {
    @required
    id: String
    @required
    status: String
    @required
    created_at: ISO8601Timestamp
    download_url: URL
}

string AccessTokenId

string PushSubscriptionId

string ExportId

// ═══════════════════════════════════════════════════════════════════════════
// List wrappers (bare-array plugin unwraps these in OpenAPI output)
// ═══════════════════════════════════════════════════════════════════════════

list BoardList { member: Board }
list ColumnList { member: Column }
list CardList { member: Card }
list CommentList { member: Comment }
list ReactionList { member: Reaction }
list NotificationList { member: Notification }
list TagList { member: Tag }
list UserList { member: User }
list WebhookList { member: Webhook }
list AccessTokenList { member: AccessToken }

// ═══════════════════════════════════════════════════════════════════════════
// Default retry configs (reused across operations)
// ═══════════════════════════════════════════════════════════════════════════

// Reusable retry annotations:
//   @readRetry    — GET/HEAD: 3 attempts, 1s base, exponential, on 429/503
//   @idempotentRetry — DELETE/PATCH/state-toggles: same as read
//   @noRetry      — POST creates, session ops: 1 attempt (no retry)

// ═══════════════════════════════════════════════════════════════════════════
// Identity (no account prefix)
// ═══════════════════════════════════════════════════════════════════════════

@readonly
@http(method: "GET", uri: "/my/identity.json")
@tags(["Identity"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation GetMyIdentity {
    output: GetMyIdentityOutput
    errors: [UnauthorizedError]
}

structure GetMyIdentityOutput {
    @required
    identity: Identity
}

// ═══════════════════════════════════════════════════════════════════════════
// Access Tokens (no account prefix — uses /my/)
// ═══════════════════════════════════════════════════════════════════════════

@readonly
@http(method: "GET", uri: "/my/access_tokens.json")
@tags(["AccessTokens"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation ListAccessTokens {
    output: ListAccessTokensOutput
    errors: [UnauthorizedError]
}

structure ListAccessTokensOutput {
    @required
    access_tokens: AccessTokenList
}

@http(method: "POST", uri: "/my/access_tokens.json")
@tags(["AccessTokens"])
@fizzyRetry(maxAttempts: 1)
operation CreateAccessToken {
    input: CreateAccessTokenInput
    output: CreateAccessTokenOutput
    errors: [UnauthorizedError, ValidationError]
}

structure CreateAccessTokenInput {
    @required
    description: String

    @required
    permission: String
}

structure CreateAccessTokenOutput {
    @required
    access_token: AccessToken
}

@idempotent
@http(method: "DELETE", uri: "/my/access_tokens/{accessTokenId}")
@tags(["AccessTokens"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation DeleteAccessToken {
    input: DeleteAccessTokenInput
    errors: [UnauthorizedError, NotFoundError]
}

structure DeleteAccessTokenInput {
    @required
    @httpLabel
    accessTokenId: AccessTokenId
}

// ═══════════════════════════════════════════════════════════════════════════
// Account
// ═══════════════════════════════════════════════════════════════════════════

@readonly
@http(method: "GET", uri: "/{accountId}/account/settings.json")
@tags(["Account"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation GetAccountSettings {
    input: AccountIdInput
    output: GetAccountSettingsOutput
    errors: [UnauthorizedError, ForbiddenError]
}

structure GetAccountSettingsOutput {
    @required
    settings: AccountSettings
}

@http(method: "PATCH", uri: "/{accountId}/account/settings.json")
@tags(["Account"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UpdateAccountSettings {
    input: UpdateAccountSettingsInput
    errors: [UnauthorizedError, ForbiddenError, ValidationError]
}

structure UpdateAccountSettingsInput {
    @required
    @httpLabel
    accountId: AccountId

    name: String
}

@readonly
@http(method: "GET", uri: "/{accountId}/account/join_code.json")
@tags(["Account"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation GetJoinCode {
    input: AccountIdInput
    output: GetJoinCodeOutput
    errors: [UnauthorizedError, ForbiddenError]
}

structure GetJoinCodeOutput {
    @required
    join_code: JoinCode
}

@http(method: "PATCH", uri: "/{accountId}/account/join_code.json")
@tags(["Account"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UpdateJoinCode {
    input: UpdateJoinCodeInput
    errors: [UnauthorizedError, ForbiddenError, ValidationError]
}

structure UpdateJoinCodeInput {
    @required
    @httpLabel
    accountId: AccountId

    usage_limit: Integer
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/account/join_code.json")
@tags(["Account"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation ResetJoinCode {
    input: AccountIdInput
    errors: [UnauthorizedError, ForbiddenError]
}

@idempotent
@http(method: "PUT", uri: "/{accountId}/account/entropy.json")
@tags(["Account"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UpdateAccountEntropy {
    input: UpdateAccountEntropyInput
    output: UpdateAccountEntropyOutput
    errors: [UnauthorizedError, ForbiddenError, ValidationError]
}

structure UpdateAccountEntropyInput {
    @required
    @httpLabel
    accountId: AccountId

    auto_postpone_period_in_days: Integer
}

structure UpdateAccountEntropyOutput {
    @required
    settings: AccountSettings
}

@http(method: "POST", uri: "/{accountId}/account/exports.json")
@tags(["Account"])
@fizzyRetry(maxAttempts: 1)
operation CreateAccountExport {
    input: AccountIdInput
    output: CreateAccountExportOutput
    errors: [UnauthorizedError, ForbiddenError]
}

structure CreateAccountExportOutput {
    @required
    export: AccountExport
}

@readonly
@http(method: "GET", uri: "/{accountId}/account/exports/{exportId}")
@tags(["Account"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation GetAccountExport {
    input: GetAccountExportInput
    output: GetAccountExportOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure GetAccountExportInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    exportId: ExportId
}

structure GetAccountExportOutput {
    @required
    export: AccountExport
}

// Shared input for account-only operations
structure AccountIdInput {
    @required
    @httpLabel
    accountId: AccountId
}

// ═══════════════════════════════════════════════════════════════════════════
// Boards
// ═══════════════════════════════════════════════════════════════════════════

@readonly
@http(method: "GET", uri: "/{accountId}/boards.json")
@tags(["Boards"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
@fizzyPagination(style: "link", pageParam: "page")
operation ListBoards {
    input: ListBoardsInput
    output: ListBoardsOutput
    errors: [UnauthorizedError, ForbiddenError]
}

structure ListBoardsInput {
    @required
    @httpLabel
    accountId: AccountId
}

structure ListBoardsOutput {
    @required
    boards: BoardList
}

@http(method: "POST", uri: "/{accountId}/boards.json")
@tags(["Boards"])
@fizzyRetry(maxAttempts: 1)
operation CreateBoard {
    input: CreateBoardInput
    output: CreateBoardOutput
    errors: [UnauthorizedError, ForbiddenError, ValidationError]
}

structure CreateBoardInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    name: String

    all_access: Boolean

    auto_postpone_period_in_days: Integer

    public_description: String
}

structure CreateBoardOutput {
    @required
    board: Board
}

@readonly
@http(method: "GET", uri: "/{accountId}/boards/{boardId}")
@tags(["Boards"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation GetBoard {
    input: GetBoardInput
    output: GetBoardOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure GetBoardInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId
}

structure GetBoardOutput {
    @required
    board: Board
}

@http(method: "PATCH", uri: "/{accountId}/boards/{boardId}")
@tags(["Boards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UpdateBoard {
    input: UpdateBoardInput
    output: UpdateBoardOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure UpdateBoardInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId

    name: String

    all_access: Boolean

    auto_postpone_period_in_days: Integer

    public_description: String

    user_ids: StringList
}

structure UpdateBoardOutput {
    @required
    board: Board
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/boards/{boardId}")
@tags(["Boards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation DeleteBoard {
    input: DeleteBoardInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure DeleteBoardInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId
}

@http(method: "POST", uri: "/{accountId}/boards/{boardId}/publication.json")
@tags(["Boards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation PublishBoard {
    input: BoardIdInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/boards/{boardId}/publication.json")
@tags(["Boards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UnpublishBoard {
    input: BoardIdInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@http(method: "PATCH", uri: "/{accountId}/boards/{boardId}/involvement.json")
@tags(["Boards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UpdateBoardInvolvement {
    input: UpdateBoardInvolvementInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure UpdateBoardInvolvementInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId

    involvement: String
}

@idempotent
@http(method: "PUT", uri: "/{accountId}/boards/{boardId}/entropy.json")
@tags(["Boards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UpdateBoardEntropy {
    input: UpdateBoardEntropyInput
    output: UpdateBoardEntropyOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure UpdateBoardEntropyInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId

    auto_postpone_period_in_days: Integer
}

structure UpdateBoardEntropyOutput {
    @required
    board: Board
}

@readonly
@http(method: "GET", uri: "/{accountId}/boards/{boardId}/columns/stream.json")
@tags(["Boards"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
@fizzyPagination(style: "link", pageParam: "page")
operation ListStreamCards {
    input: BoardIdInput
    output: ListStreamCardsOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure ListStreamCardsOutput {
    @required
    cards: CardList
}

@readonly
@http(method: "GET", uri: "/{accountId}/boards/{boardId}/columns/not_now.json")
@tags(["Boards"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
@fizzyPagination(style: "link", pageParam: "page")
operation ListPostponedCards {
    input: BoardIdInput
    output: ListPostponedCardsOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure ListPostponedCardsOutput {
    @required
    cards: CardList
}

@readonly
@http(method: "GET", uri: "/{accountId}/boards/{boardId}/columns/closed.json")
@tags(["Boards"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
@fizzyPagination(style: "link", pageParam: "page")
operation ListClosedCards {
    input: BoardIdInput
    output: ListClosedCardsOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure ListClosedCardsOutput {
    @required
    cards: CardList
}

// Shared input for board-only operations
structure BoardIdInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId
}

// ═══════════════════════════════════════════════════════════════════════════
// Columns
// ═══════════════════════════════════════════════════════════════════════════

@readonly
@http(method: "GET", uri: "/{accountId}/boards/{boardId}/columns.json")
@tags(["Columns"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation ListColumns {
    input: ListColumnsInput
    output: ListColumnsOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure ListColumnsInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId
}

structure ListColumnsOutput {
    @required
    columns: ColumnList
}

@http(method: "POST", uri: "/{accountId}/boards/{boardId}/columns.json")
@tags(["Columns"])
@fizzyRetry(maxAttempts: 1)
operation CreateColumn {
    input: CreateColumnInput
    output: CreateColumnOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure CreateColumnInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId

    @required
    name: String

    color: String
}

structure CreateColumnOutput {
    @required
    column: Column
}

@readonly
@http(method: "GET", uri: "/{accountId}/boards/{boardId}/columns/{columnId}")
@tags(["Columns"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation GetColumn {
    input: GetColumnInput
    output: GetColumnOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure GetColumnInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId

    @required
    @httpLabel
    columnId: ColumnId
}

structure GetColumnOutput {
    @required
    column: Column
}

@http(method: "PATCH", uri: "/{accountId}/boards/{boardId}/columns/{columnId}")
@tags(["Columns"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UpdateColumn {
    input: UpdateColumnInput
    output: UpdateColumnOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure UpdateColumnInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId

    @required
    @httpLabel
    columnId: ColumnId

    name: String

    color: String
}

structure UpdateColumnOutput {
    @required
    column: Column
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/boards/{boardId}/columns/{columnId}")
@tags(["Columns"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation DeleteColumn {
    input: DeleteColumnInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure DeleteColumnInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId

    @required
    @httpLabel
    columnId: ColumnId
}

@http(method: "POST", uri: "/{accountId}/columns/{columnId}/left_position.json")
@tags(["Columns"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation MoveColumnLeft {
    input: ColumnPositionInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@http(method: "POST", uri: "/{accountId}/columns/{columnId}/right_position.json")
@tags(["Columns"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation MoveColumnRight {
    input: ColumnPositionInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure ColumnPositionInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    columnId: ColumnId
}

// ═══════════════════════════════════════════════════════════════════════════
// Cards
// ═══════════════════════════════════════════════════════════════════════════

@readonly
@http(method: "GET", uri: "/{accountId}/cards.json")
@tags(["Cards"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
@fizzyPagination(style: "link", pageParam: "page")
operation ListCards {
    input: ListCardsInput
    output: ListCardsOutput
    errors: [UnauthorizedError, ForbiddenError]
}

structure ListCardsInput {
    @required
    @httpLabel
    accountId: AccountId

    @httpQuery("board_id")
    board_id: String

    @httpQuery("column_id")
    column_id: String

    @httpQuery("assignee_id")
    assignee_id: String

    @httpQuery("tag")
    tag: String

    @httpQuery("status")
    status: String

    @httpQuery("q")
    q: String
}

structure ListCardsOutput {
    @required
    cards: CardList
}

@http(method: "POST", uri: "/{accountId}/cards.json")
@tags(["Cards"])
@fizzyRetry(maxAttempts: 1)
operation CreateCard {
    input: CreateCardInput
    output: CreateCardOutput
    errors: [UnauthorizedError, ForbiddenError, ValidationError]
}

structure CreateCardInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    title: String

    board_id: String

    column_id: String

    description: String

    assignee_ids: StringList

    tag_names: TagNames

    image: String

    created_at: String

    last_active_at: String
}

list StringList {
    member: String
}

structure CreateCardOutput {
    @required
    card: Card
}

@readonly
@http(method: "GET", uri: "/{accountId}/cards/{cardNumber}")
@tags(["Cards"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation GetCard {
    input: GetCardInput
    output: GetCardOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure GetCardInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber
}

structure GetCardOutput {
    @required
    card: Card
}

@http(method: "PATCH", uri: "/{accountId}/cards/{cardNumber}")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UpdateCard {
    input: UpdateCardInput
    output: UpdateCardOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure UpdateCardInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    title: String

    description: String

    column_id: String

    image: String

    created_at: String
}

structure UpdateCardOutput {
    @required
    card: Card
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/cards/{cardNumber}")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation DeleteCard {
    input: DeleteCardInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure DeleteCardInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber
}

// Card state toggles — naturally idempotent, retriable

@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/closure.json")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation CloseCard {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/cards/{cardNumber}/closure.json")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation ReopenCard {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/not_now.json")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation PostponeCard {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/triage.json")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation TriageCard {
    input: TriageCardInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure TriageCardInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    column_id: String
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/cards/{cardNumber}/triage.json")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UnTriageCard {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/goldness.json")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation GoldCard {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/cards/{cardNumber}/goldness.json")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UngoldCard {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/assignments.json")
@tags(["Cards"])
@fizzyRetry(maxAttempts: 1)
operation AssignCard {
    input: AssignCardInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure AssignCardInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    @required
    assignee_id: UserId
}

@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/self_assignment.json")
@tags(["Cards"])
@fizzyRetry(maxAttempts: 1)
operation SelfAssignCard {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/taggings.json")
@tags(["Cards"])
@fizzyRetry(maxAttempts: 1)
operation TagCard {
    input: TagCardInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure TagCardInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    @required
    tag_title: String
}

@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/watch.json")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation WatchCard {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/cards/{cardNumber}/watch.json")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UnwatchCard {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/pin.json")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation PinCard {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/cards/{cardNumber}/pin.json")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UnpinCard {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@http(method: "PATCH", uri: "/{accountId}/cards/{cardNumber}/board.json")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation MoveCard {
    input: MoveCardInput
    output: MoveCardOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure MoveCardInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    @required
    board_id: BoardId

    column_id: ColumnId
}

structure MoveCardOutput {
    @required
    card: Card
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/cards/{cardNumber}/image.json")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation DeleteCardImage {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/reading.json")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation MarkCardRead {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/cards/{cardNumber}/reading.json")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation MarkCardUnread {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/publish.json")
@tags(["Cards"])
@fizzyRetry(maxAttempts: 1)
operation PublishCard {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

// Shared input for card operations that only need accountId + cardNumber
structure CardNumberInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber
}

// ═══════════════════════════════════════════════════════════════════════════
// Comments
// ═══════════════════════════════════════════════════════════════════════════

@readonly
@http(method: "GET", uri: "/{accountId}/cards/{cardNumber}/comments.json")
@tags(["Comments"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
@fizzyPagination(style: "link", pageParam: "page")
operation ListComments {
    input: ListCommentsInput
    output: ListCommentsOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure ListCommentsInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber
}

structure ListCommentsOutput {
    @required
    comments: CommentList
}

@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/comments.json")
@tags(["Comments"])
@fizzyRetry(maxAttempts: 1)
operation CreateComment {
    input: CreateCommentInput
    output: CreateCommentOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure CreateCommentInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    @required
    body: String

    created_at: String
}

structure CreateCommentOutput {
    @required
    comment: Comment
}

@readonly
@http(method: "GET", uri: "/{accountId}/cards/{cardNumber}/comments/{commentId}")
@tags(["Comments"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation GetComment {
    input: GetCommentInput
    output: GetCommentOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure GetCommentInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    @required
    @httpLabel
    commentId: CommentId
}

structure GetCommentOutput {
    @required
    comment: Comment
}

@http(method: "PATCH", uri: "/{accountId}/cards/{cardNumber}/comments/{commentId}")
@tags(["Comments"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UpdateComment {
    input: UpdateCommentInput
    output: UpdateCommentOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure UpdateCommentInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    @required
    @httpLabel
    commentId: CommentId

    @required
    body: String
}

structure UpdateCommentOutput {
    @required
    comment: Comment
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/cards/{cardNumber}/comments/{commentId}")
@tags(["Comments"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation DeleteComment {
    input: DeleteCommentInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure DeleteCommentInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    @required
    @httpLabel
    commentId: CommentId
}

// ═══════════════════════════════════════════════════════════════════════════
// Steps
// ═══════════════════════════════════════════════════════════════════════════

@readonly
@http(method: "GET", uri: "/{accountId}/cards/{cardNumber}/steps.json")
@tags(["Steps"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation ListSteps {
    input: CardNumberInput
    output: ListStepsOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure ListStepsOutput {
    @required
    steps: StepList
}

@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/steps.json")
@tags(["Steps"])
@fizzyRetry(maxAttempts: 1)
operation CreateStep {
    input: CreateStepInput
    output: CreateStepOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure CreateStepInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    @required
    content: String

    completed: Boolean
}

structure CreateStepOutput {
    @required
    step: Step
}

@readonly
@http(method: "GET", uri: "/{accountId}/cards/{cardNumber}/steps/{stepId}")
@tags(["Steps"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation GetStep {
    input: GetStepInput
    output: GetStepOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure GetStepInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    @required
    @httpLabel
    stepId: StepId
}

structure GetStepOutput {
    @required
    step: Step
}

@http(method: "PATCH", uri: "/{accountId}/cards/{cardNumber}/steps/{stepId}")
@tags(["Steps"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UpdateStep {
    input: UpdateStepInput
    output: UpdateStepOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure UpdateStepInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    @required
    @httpLabel
    stepId: StepId

    content: String

    completed: Boolean
}

structure UpdateStepOutput {
    @required
    step: Step
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/cards/{cardNumber}/steps/{stepId}")
@tags(["Steps"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation DeleteStep {
    input: DeleteStepInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure DeleteStepInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    @required
    @httpLabel
    stepId: StepId
}

// ═══════════════════════════════════════════════════════════════════════════
// Reactions
// ═══════════════════════════════════════════════════════════════════════════

// Card reactions

@readonly
@http(method: "GET", uri: "/{accountId}/cards/{cardNumber}/reactions.json")
@tags(["Reactions"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation ListCardReactions {
    input: CardNumberInput
    output: ListCardReactionsOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure ListCardReactionsOutput {
    @required
    reactions: ReactionList
}

@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/reactions.json")
@tags(["Reactions"])
@fizzyRetry(maxAttempts: 1)
operation CreateCardReaction {
    input: CreateCardReactionInput
    output: CreateCardReactionOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure CreateCardReactionInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    @required
    content: String
}

structure CreateCardReactionOutput {
    @required
    reaction: Reaction
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/cards/{cardNumber}/reactions/{reactionId}")
@tags(["Reactions"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation DeleteCardReaction {
    input: DeleteCardReactionInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure DeleteCardReactionInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    @required
    @httpLabel
    reactionId: ReactionId
}

// Comment reactions

@readonly
@http(method: "GET", uri: "/{accountId}/cards/{cardNumber}/comments/{commentId}/reactions.json")
@tags(["Reactions"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation ListCommentReactions {
    input: ListCommentReactionsInput
    output: ListCommentReactionsOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure ListCommentReactionsInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    @required
    @httpLabel
    commentId: CommentId
}

structure ListCommentReactionsOutput {
    @required
    reactions: ReactionList
}

@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/comments/{commentId}/reactions.json")
@tags(["Reactions"])
@fizzyRetry(maxAttempts: 1)
operation CreateCommentReaction {
    input: CreateCommentReactionInput
    output: CreateCommentReactionOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure CreateCommentReactionInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    @required
    @httpLabel
    commentId: CommentId

    @required
    content: String
}

structure CreateCommentReactionOutput {
    @required
    reaction: Reaction
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/cards/{cardNumber}/comments/{commentId}/reactions/{reactionId}")
@tags(["Reactions"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation DeleteCommentReaction {
    input: DeleteCommentReactionInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure DeleteCommentReactionInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    cardNumber: CardNumber

    @required
    @httpLabel
    commentId: CommentId

    @required
    @httpLabel
    reactionId: ReactionId
}

// ═══════════════════════════════════════════════════════════════════════════
// Notifications
// ═══════════════════════════════════════════════════════════════════════════

@readonly
@http(method: "GET", uri: "/{accountId}/notifications.json")
@tags(["Notifications"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
@fizzyPagination(style: "link", pageParam: "page")
operation ListNotifications {
    input: ListNotificationsInput
    output: ListNotificationsOutput
    errors: [UnauthorizedError, ForbiddenError]
}

structure ListNotificationsInput {
    @required
    @httpLabel
    accountId: AccountId

    @httpQuery("read")
    read: Boolean
}

structure ListNotificationsOutput {
    @required
    notifications: NotificationList
}

@http(method: "POST", uri: "/{accountId}/notifications/{notificationId}/reading.json")
@tags(["Notifications"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation ReadNotification {
    input: ReadNotificationInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure ReadNotificationInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    notificationId: NotificationId
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/notifications/{notificationId}/reading.json")
@tags(["Notifications"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UnreadNotification {
    input: UnreadNotificationInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure UnreadNotificationInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    notificationId: NotificationId
}

@http(method: "POST", uri: "/{accountId}/notifications/bulk_reading.json")
@tags(["Notifications"])
@fizzyRetry(maxAttempts: 1)
operation BulkReadNotifications {
    input: BulkReadNotificationsInput
    errors: [UnauthorizedError, ForbiddenError]
}

structure BulkReadNotificationsInput {
    @required
    @httpLabel
    accountId: AccountId

    notification_ids: NotificationIdList
}

list NotificationIdList {
    member: NotificationId
}

@readonly
@http(method: "GET", uri: "/{accountId}/notifications/tray.json")
@tags(["Notifications"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation GetNotificationTray {
    input: GetNotificationTrayInput
    output: GetNotificationTrayOutput
    errors: [UnauthorizedError, ForbiddenError]
}

structure GetNotificationTrayInput {
    @required
    @httpLabel
    accountId: AccountId

    @httpQuery("include_read")
    include_read: Boolean
}

structure GetNotificationTrayOutput {
    @required
    notifications: NotificationList
}

@readonly
@http(method: "GET", uri: "/{accountId}/notifications/settings.json")
@tags(["Notifications"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation GetNotificationSettings {
    input: GetNotificationSettingsInput
    output: GetNotificationSettingsOutput
    errors: [UnauthorizedError, ForbiddenError]
}

structure GetNotificationSettingsInput {
    @required
    @httpLabel
    accountId: AccountId
}

structure GetNotificationSettingsOutput {
    @required
    settings: NotificationSettings
}

@http(method: "PATCH", uri: "/{accountId}/notifications/settings.json")
@tags(["Notifications"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UpdateNotificationSettings {
    input: UpdateNotificationSettingsInput
    errors: [UnauthorizedError, ForbiddenError, ValidationError]
}

structure UpdateNotificationSettingsInput {
    @required
    @httpLabel
    accountId: AccountId

    bundle_email_frequency: String
}

// ═══════════════════════════════════════════════════════════════════════════
// Search
// ═══════════════════════════════════════════════════════════════════════════

@readonly
@http(method: "GET", uri: "/{accountId}/search.json")
@tags(["Search"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
@fizzyPagination(style: "link", pageParam: "page")
operation SearchCards {
    input: SearchCardsInput
    output: SearchCardsOutput
    errors: [UnauthorizedError, ForbiddenError]
}

structure SearchCardsInput {
    @required
    @httpLabel
    accountId: AccountId

    @httpQuery("q")
    @required
    q: String
}

structure SearchCardsOutput {
    @required
    cards: CardList
}

// ═══════════════════════════════════════════════════════════════════════════
// Tags
// ═══════════════════════════════════════════════════════════════════════════

@readonly
@http(method: "GET", uri: "/{accountId}/tags.json")
@tags(["Tags"])
@fizzyPagination(style: "link", pageParam: "page")
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation ListTags {
    input: ListTagsInput
    output: ListTagsOutput
    errors: [UnauthorizedError, ForbiddenError]
}

structure ListTagsInput {
    @required
    @httpLabel
    accountId: AccountId
}

structure ListTagsOutput {
    @required
    tags: TagList
}

// ═══════════════════════════════════════════════════════════════════════════
// Users
// ═══════════════════════════════════════════════════════════════════════════

@readonly
@http(method: "GET", uri: "/{accountId}/users.json")
@tags(["Users"])
@fizzyPagination(style: "link", pageParam: "page")
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation ListUsers {
    input: ListUsersInput
    output: ListUsersOutput
    errors: [UnauthorizedError, ForbiddenError]
}

structure ListUsersInput {
    @required
    @httpLabel
    accountId: AccountId
}

structure ListUsersOutput {
    @required
    users: UserList
}

@readonly
@http(method: "GET", uri: "/{accountId}/users/{userId}")
@tags(["Users"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation GetUser {
    input: GetUserInput
    output: GetUserOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure GetUserInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    userId: UserId
}

structure GetUserOutput {
    @required
    user: User
}

@http(method: "PATCH", uri: "/{accountId}/users/{userId}")
@tags(["Users"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UpdateUser {
    input: UpdateUserInput
    output: UpdateUserOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure UpdateUserInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    userId: UserId

    name: String
}

structure UpdateUserOutput {
    @required
    user: User
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/users/{userId}")
@tags(["Users"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation DeactivateUser {
    input: DeactivateUserInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure DeactivateUserInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    userId: UserId
}

@http(method: "PATCH", uri: "/{accountId}/users/{userId}/role.json")
@tags(["Users"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UpdateUserRole {
    input: UpdateUserRoleInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure UpdateUserRoleInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    userId: UserId

    @required
    role: String
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/users/{userId}/avatar")
@tags(["Users"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation DeleteUserAvatar {
    input: DeleteUserAvatarInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure DeleteUserAvatarInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    userId: UserId
}

@http(method: "POST", uri: "/{accountId}/users/{userId}/push_subscriptions.json")
@tags(["Users"])
@fizzyRetry(maxAttempts: 1)
operation CreatePushSubscription {
    input: CreatePushSubscriptionInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure CreatePushSubscriptionInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    userId: UserId

    @required
    endpoint: String

    @required
    p256dh_key: String

    @required
    auth_key: String
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/users/{userId}/push_subscriptions/{pushSubscriptionId}")
@tags(["Users"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation DeletePushSubscription {
    input: DeletePushSubscriptionInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure DeletePushSubscriptionInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    userId: UserId

    @required
    @httpLabel
    pushSubscriptionId: PushSubscriptionId
}

// ═══════════════════════════════════════════════════════════════════════════
// Pins (no account prefix — uses /my/)
// ═══════════════════════════════════════════════════════════════════════════

@readonly
@http(method: "GET", uri: "/my/pins.json")
@tags(["Pins"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation ListPins {
    output: ListPinsOutput
    errors: [UnauthorizedError]
}

structure ListPinsOutput {
    @required
    cards: CardList
}

// ═══════════════════════════════════════════════════════════════════════════
// Uploads (ActiveStorage direct upload — no .json suffix)
// ═══════════════════════════════════════════════════════════════════════════

@http(method: "POST", uri: "/{accountId}/rails/active_storage/direct_uploads")
@tags(["Uploads"])
@fizzyRetry(maxAttempts: 1)
operation CreateDirectUpload {
    input: CreateDirectUploadInput
    output: CreateDirectUploadOutput
    errors: [UnauthorizedError, ForbiddenError, ValidationError]
}

structure CreateDirectUploadInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    filename: String

    @required
    content_type: String

    @required
    byte_size: Long

    @required
    checksum: String
}

structure CreateDirectUploadOutput {
    @required
    upload: DirectUpload
}

// ═══════════════════════════════════════════════════════════════════════════
// Webhooks
// ═══════════════════════════════════════════════════════════════════════════

@readonly
@http(method: "GET", uri: "/{accountId}/boards/{boardId}/webhooks.json")
@tags(["Webhooks"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation ListWebhooks {
    input: ListWebhooksInput
    output: ListWebhooksOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure ListWebhooksInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId
}

structure ListWebhooksOutput {
    @required
    webhooks: WebhookList
}

@http(method: "POST", uri: "/{accountId}/boards/{boardId}/webhooks.json")
@tags(["Webhooks"])
@fizzyRetry(maxAttempts: 1)
operation CreateWebhook {
    input: CreateWebhookInput
    output: CreateWebhookOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure CreateWebhookInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId

    @required
    name: String

    @required
    url: URL

    subscribed_actions: WebhookActions
}

structure CreateWebhookOutput {
    @required
    webhook: Webhook
}

@readonly
@http(method: "GET", uri: "/{accountId}/boards/{boardId}/webhooks/{webhookId}")
@tags(["Webhooks"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation GetWebhook {
    input: GetWebhookInput
    output: GetWebhookOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure GetWebhookInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId

    @required
    @httpLabel
    webhookId: WebhookId
}

structure GetWebhookOutput {
    @required
    webhook: Webhook
}

@http(method: "PATCH", uri: "/{accountId}/boards/{boardId}/webhooks/{webhookId}")
@tags(["Webhooks"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UpdateWebhook {
    input: UpdateWebhookInput
    output: UpdateWebhookOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, ValidationError]
}

structure UpdateWebhookInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId

    @required
    @httpLabel
    webhookId: WebhookId

    name: String

    url: URL

    subscribed_actions: WebhookActions
}

structure UpdateWebhookOutput {
    @required
    webhook: Webhook
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/boards/{boardId}/webhooks/{webhookId}")
@tags(["Webhooks"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation DeleteWebhook {
    input: DeleteWebhookInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure DeleteWebhookInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId

    @required
    @httpLabel
    webhookId: WebhookId
}

@http(method: "POST", uri: "/{accountId}/boards/{boardId}/webhooks/{webhookId}/activation.json")
@tags(["Webhooks"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation ActivateWebhook {
    input: ActivateWebhookInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure ActivateWebhookInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId

    @required
    @httpLabel
    webhookId: WebhookId
}

// ═══════════════════════════════════════════════════════════════════════════
// Sessions (no account prefix — server-root-scoped)
// ═══════════════════════════════════════════════════════════════════════════

@http(method: "POST", uri: "/session.json")
@tags(["Sessions"])
@fizzyRetry(maxAttempts: 1)
operation CreateSession {
    input: CreateSessionInput
    output: CreateSessionOutput
    errors: [ValidationError, BadRequestError]
}

structure CreateSessionInput {
    @fizzySensitive(category: "pii", redact: true)
    @required
    email_address: EmailAddress
}

structure CreateSessionOutput {
    @required
    pending_authentication: PendingAuthentication
}

@http(method: "POST", uri: "/session/magic_link.json")
@tags(["Sessions"])
@fizzyRetry(maxAttempts: 1)
operation RedeemMagicLink {
    input: RedeemMagicLinkInput
    output: RedeemMagicLinkOutput
    errors: [UnauthorizedError, ValidationError]
}

structure RedeemMagicLinkInput {
    @required
    token: String
}

structure RedeemMagicLinkOutput {
    @required
    session: SessionAuthorization
}

@idempotent
@http(method: "DELETE", uri: "/session.json")
@tags(["Sessions"])
@fizzyRetry(maxAttempts: 1)
operation DestroySession {
    errors: [UnauthorizedError]
}

@http(method: "POST", uri: "/signup/completion.json", code: 201)
@tags(["Sessions"])
@fizzyRetry(maxAttempts: 1)
operation CompleteSignup {
    input: CompleteSignupInput
    errors: [UnauthorizedError, ValidationError]
}

structure CompleteSignupInput {
    @required
    full_name: PersonName
}

@http(method: "POST", uri: "/users/joins.json", code: 204)
@tags(["Sessions"])
@fizzyRetry(maxAttempts: 1)
operation CompleteJoin {
    input: CompleteJoinInput
    errors: [UnauthorizedError, ValidationError]
}

structure CompleteJoinInput {
    @required
    name: PersonName
}

// ═══════════════════════════════════════════════════════════════════════════
// Devices (push token registration — no .json suffix)
// ═══════════════════════════════════════════════════════════════════════════

@http(method: "POST", uri: "/{accountId}/devices")
@tags(["Devices"])
@fizzyRetry(maxAttempts: 1)
operation RegisterDevice {
    input: RegisterDeviceInput
    errors: [UnauthorizedError, ForbiddenError, ValidationError]
}

structure RegisterDeviceInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    token: String

    @required
    platform: String

    name: String
}

@idempotent
@http(method: "DELETE", uri: "/{accountId}/devices/{deviceToken}")
@tags(["Devices"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UnregisterDevice {
    input: UnregisterDeviceInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure UnregisterDeviceInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    deviceToken: DeviceToken
}
