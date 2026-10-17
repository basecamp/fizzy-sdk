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
        UpdateMyTimezone

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
        ListBoardAccesses
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
        ListColumnCards
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

        // Activities
        ListActivities

        // Tags
        ListTags

        // Users
        ListUsers
        GetUser
        UpdateUser
        DeactivateUser
        RequestEmailAddressChange
        ConfirmEmailAddressChange
        CreateUserDataExport
        GetUserDataExport
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
        ListWebhookDeliveries

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
    public_description: String
    public_description_html: String
    public_url: URL
    user_ids: StringList
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
    cards_url: URL
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

structure BoardAccessUser {
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
    @required
    has_access: Boolean
    involvement: String
}

list BoardAccessUserList {
    member: BoardAccessUser
}

structure BoardAccesses {
    @required
    board_id: BoardId
    @required
    all_access: Boolean
    @required
    users: BoardAccessUserList
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

structure ActivityParticulars {
    assignee_ids: StringList
    old_board: String
    new_board: String
    old_title: String
    new_title: String
    column: String
}

structure ActivityEventable {
    @required
    id: String
    number: CardNumber
    title: String
    status: String
    description: String
    description_html: String
    image_url: URL
    has_attachments: Boolean
    tags: TagNames
    closed: Boolean
    postponed: Boolean
    golden: Boolean
    last_active_at: ISO8601Timestamp
    created_at: ISO8601Timestamp
    updated_at: ISO8601Timestamp
    body: RichTextBody
    creator: User
    card: CardRef
    board: Board
    column: Column
    assignees: UserList
    has_more_assignees: Boolean
    comments_url: URL
    reactions_url: URL
    steps: StepList
    @required
    url: URL
}

structure Activity {
    @required
    id: String
    @required
    action: String
    @required
    created_at: ISO8601Timestamp
    @required
    description: String
    @required
    particulars: ActivityParticulars
    @required
    url: URL
    @required
    eventable_type: String
    @required
    eventable: ActivityEventable
    @required
    board: Board
    @required
    creator: User
}

list ActivityList {
    member: Activity
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
    payload_url: URL
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
    updated_at: ISO8601Timestamp
    board: Board
}

list WebhookActions {
    member: String
}

map StringMap {
    key: String
    value: String
}

structure WebhookDeliveryRequest {
    headers: StringMap
}

structure WebhookDeliveryResponse {
    code: Integer
    error: String
}

structure WebhookDeliveryEventCreator {
    @required
    id: UserId
    @required
    name: PersonName
}

structure WebhookDeliveryEventEventable {
    @required
    type: String
    @required
    id: String
    @required
    url: URL
}

structure WebhookDeliveryEvent {
    @required
    id: String
    @required
    action: String
    @required
    created_at: ISO8601Timestamp
    creator: WebhookDeliveryEventCreator
    eventable: WebhookDeliveryEventEventable
}

structure WebhookDelivery {
    @required
    id: String
    @required
    state: String
    @required
    created_at: ISO8601Timestamp
    @required
    updated_at: ISO8601Timestamp
    request: WebhookDeliveryRequest
    response: WebhookDeliveryResponse
    event: WebhookDeliveryEvent
}

list WebhookDeliveryList {
    member: WebhookDelivery
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
    name: PersonName
    @fizzySensitive(category: "pii", redact: true)
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

structure DataExport {
    @required
    id: String
    @required
    status: String
    @required
    created_at: ISO8601Timestamp
    download_url: URL
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
    usage_count: Integer
    usage_limit: Integer
    active: Boolean
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
// Identity
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

/// Sets the caller's time zone. The name isn't validated: one that ActiveSupport::TimeZone doesn't recognize is stored, succeeds with 204, and reads back as UTC.
@http(method: "PATCH", uri: "/{accountId}/my/timezone.json", code: 204)
@tags(["Identity"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation UpdateMyTimezone {
    input: UpdateMyTimezoneInput
    errors: [UnauthorizedError, ValidationError]
}

structure UpdateMyTimezoneInput {
    @required
    @httpLabel
    accountId: AccountId

    /// An IANA or Rails time zone name, such as "America/Chicago" or "Central Time (US & Canada)".
    @required
    timezone_name: String
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

    /// The account name. Required: the controller expects an `account` object, so an empty body is a 400.
    @required
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

    /// How many times the join code can be redeemed. Fizzy accepts up to 10,000,000,000, but this 32-bit field holds at most 2,147,483,647. Required: an empty body is a 400.
    @required
    usage_limit: Integer
}

/// Replaces the join code with a newly generated one and resets its usage count. Each call mints a different code and invalidates the previous one, so a retry invalidates the code the first call issued: not idempotent.
@suppress(["HttpMethodSemantics.MissingIdempotentTrait"])
@http(method: "DELETE", uri: "/{accountId}/account/join_code.json")
@tags(["Account"])
@fizzyRetry(maxAttempts: 1)
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

    /// Days of inactivity before a card is auto-postponed. One of 3, 7, 11, 30, 90 or 365 (Entropy::AUTO_POSTPONE_PERIODS_IN_DAYS); any other value is rejected with 422. Required: an empty body is a 400.
    @required
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

    /// Days of inactivity before a card is auto-postponed. One of 3, 7, 11, 30, 90 or 365 (Entropy::AUTO_POSTPONE_PERIODS_IN_DAYS); any other value is rejected with 422.
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

@readonly
@http(method: "GET", uri: "/{accountId}/boards/{boardId}/accesses.json")
@tags(["Boards"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation ListBoardAccesses {
    input: ListBoardAccessesInput
    output: ListBoardAccessesOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure ListBoardAccessesInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    boardId: BoardId

    @httpQuery("page")
    page: Integer
}

structure ListBoardAccessesOutput {
    @required
    accesses: BoardAccesses
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

/// Updates a board. Send at least one of name, all_access, auto_postpone_period_in_days or public_description: the controller expects a `board` object, so a body without any of them (including one carrying only user_ids) is a 400.
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

    /// Days of inactivity before a card is auto-postponed. One of 3, 7, 11, 30, 90 or 365 (Entropy::AUTO_POSTPONE_PERIODS_IN_DAYS); any other value is rejected with 422.
    auto_postpone_period_in_days: Integer

    public_description: String

    /// Replaces the board's membership: users listed are granted access and every current member not listed loses it. Omit it to leave access unchanged. It can't be sent alone (see the operation).
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

    /// The caller's involvement with the board: "access_only" or "watching" (Access#involvement). Required: the controller assigns it unconditionally.
    @required
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

    /// Days of inactivity before a card is auto-postponed. One of 3, 7, 11, 30, 90 or 365 (Entropy::AUTO_POSTPONE_PERIODS_IN_DAYS); any other value is rejected with 422. Required: an empty body is a 400.
    @required
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

@readonly
@http(method: "GET", uri: "/{accountId}/boards/{boardId}/columns/{columnId}/cards.json")
@tags(["Cards"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
@fizzyPagination(style: "link", pageParam: "page")
operation ListColumnCards {
    input: ListColumnCardsInput
    output: ListColumnCardsOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure ListColumnCardsInput {
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

structure ListColumnCardsOutput {
    @required
    cards: CardList
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

    /// The column color, as its CSS value: "var(--color-card-default)" (Blue), "var(--color-card-1)" (Gray), "var(--color-card-2)" (Tan), "var(--color-card-3)" (Yellow), "var(--color-card-4)" (Lime), "var(--color-card-5)" (Aqua), "var(--color-card-6)" (Violet), "var(--color-card-7)" (Purple) or "var(--color-card-8)" (Pink) (Color::COLORS). Any other value is stored but reads back as Blue.
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

/// Updates a column. Send at least one of name or color: the controller expects a `column` object, so an empty body is a 400.
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

    /// The column color, as its CSS value: "var(--color-card-default)" (Blue), "var(--color-card-1)" (Gray), "var(--color-card-2)" (Tan), "var(--color-card-3)" (Yellow), "var(--color-card-4)" (Lime), "var(--color-card-5)" (Aqua), "var(--color-card-6)" (Violet), "var(--color-card-7)" (Purple) or "var(--color-card-8)" (Pink) (Color::COLORS). Any other value is stored but reads back as Blue.
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

/// Swaps the column with its left neighbor. Each call moves it again, so it is not idempotent; at the leftmost edge there is no neighbor and the call succeeds without changing anything.
@http(method: "POST", uri: "/{accountId}/columns/{columnId}/left_position.json")
@tags(["Columns"])
@fizzyRetry(maxAttempts: 1)
operation MoveColumnLeft {
    input: ColumnPositionInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

/// Swaps the column with its right neighbor. Each call moves it again, so it is not idempotent; at the rightmost edge there is no neighbor and the call succeeds without changing anything.
@http(method: "POST", uri: "/{accountId}/columns/{columnId}/right_position.json")
@tags(["Columns"])
@fizzyRetry(maxAttempts: 1)
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

    @httpQuery("board_ids[]")
    board_ids: StringList

    @httpQuery("tag_ids[]")
    tag_ids: StringList

    @httpQuery("assignee_ids[]")
    assignee_ids: StringList

    @httpQuery("creator_ids[]")
    creator_ids: StringList

    @httpQuery("closer_ids[]")
    closer_ids: StringList

    @httpQuery("card_ids[]")
    card_ids: StringList

    @httpQuery("column_ids[]")
    column_ids: StringList

    /// Which cards to list: "all" (default, open cards), "maybe" (awaiting triage), "closed", "not_now", "stalled", "postponing_soon" or "golden". Any other value lists the same cards as "all".
    @httpQuery("indexed_by")
    indexed_by: String

    /// "latest" (default, most recently active first), "newest" or "oldest" (by creation). Any other value sorts as "latest".
    @httpQuery("sorted_by")
    sorted_by: String

    /// "unassigned" lists only cards with no assignee; any other value is ignored.
    @httpQuery("assignment_status")
    assignment_status: String

    /// Created within: "today", "yesterday", "thisweek", "lastweek", "thismonth", "lastmonth", "thisyear" or "lastyear" (TimeWindowParser); any other value is ignored.
    @httpQuery("creation")
    creation: String

    /// Closed within: "today", "yesterday", "thisweek", "lastweek", "thismonth", "lastmonth", "thisyear" or "lastyear" (TimeWindowParser); any other value is ignored.
    @httpQuery("closure")
    closure: String

    @httpQuery("terms[]")
    terms: StringList
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

    /// The board to create the card on. Required: CardsController finds it unconditionally.
    @required
    board_id: String

    description: String

    /// The signed blob id of an image uploaded with CreateDirectUpload. A caller that can't make the upload has no value to send here.
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

/// Updates a card. Send at least one of title, description, image or created_at: the controller expects a `card` object, so an empty body is a 400. Moving a card between columns is TriageCard, and between boards MoveCard.
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

    /// The signed blob id of an image uploaded with CreateDirectUpload. A caller that can't make the upload has no value to send here.
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

/// Moves the card to Not Now. Each call records an event, which notifies webhooks and adds a system comment to the card, even when the card's state doesn't change, so it is not safe to retry.
@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/not_now.json")
@tags(["Cards"])
@fizzyRetry(maxAttempts: 1)
operation PostponeCard {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

/// Triages the card into a column of its board. Each call records an event, which notifies webhooks and adds a system comment to the card, even when the card's state doesn't change, so it is not safe to retry.
@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/triage.json")
@tags(["Cards"])
@fizzyRetry(maxAttempts: 1)
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

    /// A column on the card's board. Required: the controller finds it unconditionally.
    @required
    column_id: String
}

/// Sends the card back to triage (Maybe?). Each call records an event, which notifies webhooks and adds a system comment to the card, even when the card's state doesn't change, so it is not safe to retry.
@suppress(["HttpMethodSemantics.MissingIdempotentTrait"])
@http(method: "DELETE", uri: "/{accountId}/cards/{cardNumber}/triage.json")
@tags(["Cards"])
@fizzyRetry(maxAttempts: 1)
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

/// Assigns the user to the card, or unassigns them if they are already assigned. This is a toggle: calling it again undoes it, and both outcomes return 204, so a retry or a repeat reverses the first call. Check the card first when the outcome matters.
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

/// Assigns the caller to the card, or unassigns them if they are already assigned. This is a toggle: calling it again undoes it, and both outcomes return 204, so a retry or a repeat reverses the first call. Check the card first when the outcome matters.
@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/self_assignment.json")
@tags(["Cards"])
@fizzyRetry(maxAttempts: 1)
operation SelfAssignCard {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

/// Tags the card, or untags it if it already has the tag. The tag is created when the account has none with that title. This is a toggle: calling it again undoes it, and both outcomes return 204, so a retry or a repeat reverses the first call. Check the card first when the outcome matters.
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

    /// The tag's title; surrounding whitespace and a leading "#" are stripped.
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

/// Unpins the card for the caller. Unpinning a card the caller hasn't pinned currently fails with a 500 (Card::Pinnable#unpin_by destroys a pin it didn't find), so a retry after a success fails: not idempotent.
@suppress(["HttpMethodSemantics.MissingIdempotentTrait"])
@http(method: "DELETE", uri: "/{accountId}/cards/{cardNumber}/pin.json")
@tags(["Cards"])
@fizzyRetry(maxAttempts: 1)
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

    /// The destination board. Cards::BoardsController reads no column.
    @required
    board_id: BoardId
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

/// Marks the caller's notification for the card read. When the caller has no notification for the card, the call succeeds without changing anything.
@http(method: "POST", uri: "/{accountId}/cards/{cardNumber}/reading.json")
@tags(["Cards"])
@fizzyIdempotent(natural: true)
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation MarkCardRead {
    input: CardNumberInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

/// Marks the caller's notification for the card unread. When the caller has no notification for the card, the call succeeds without changing anything.
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

/// Updates a step. Send at least one of content or completed: the controller expects a `step` object, so an empty body is a 400.
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

/// Lists the caller's notifications. It takes no read/unread filter: the first page holds up to 100 unread notifications followed by a page of read ones, and later pages hold read ones only.
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

/// Marks every unread notification of the caller read. It takes no selection.
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

    /// Ignored: Notifications::BulkReadingsController reads no ids and marks every unread notification read whatever this holds.
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

    /// "never", "every_few_hours", "daily" or "weekly" (User::Settings#bundle_email_frequency). Required: an empty body is a 400.
    @required
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
// Activities
// ═══════════════════════════════════════════════════════════════════════════

@readonly
@http(method: "GET", uri: "/{accountId}/activities.json")
@tags(["Activities"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
@fizzyPagination(style: "link", pageParam: "page")
operation ListActivities {
    input: ListActivitiesInput
    output: ListActivitiesOutput
    errors: [UnauthorizedError, ForbiddenError]
}

structure ListActivitiesInput {
    @required
    @httpLabel
    accountId: AccountId

    @httpQuery("creator_ids[]")
    creator_ids: StringList

    @httpQuery("board_ids[]")
    board_ids: StringList
}

structure ListActivitiesOutput {
    @required
    activities: ActivityList
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

    /// Required: the controller expects a `user` object, so an empty body is a 400.
    @required
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

@http(method: "POST", uri: "/{accountId}/users/{userId}/email_addresses.json")
@tags(["Users"])
@fizzyRetry(maxAttempts: 1)
operation RequestEmailAddressChange {
    input: RequestEmailAddressChangeInput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, BadRequestError, ValidationError, RateLimitError]
}

structure RequestEmailAddressChangeInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    userId: UserId

    @fizzySensitive(category: "pii", redact: true)
    @required
    email_address: EmailAddress
}

@http(method: "POST", uri: "/{accountId}/users/{userId}/email_addresses/{emailAddressToken}/confirmation.json")
@tags(["Users"])
@fizzyRetry(maxAttempts: 1)
operation ConfirmEmailAddressChange {
    input: ConfirmEmailAddressChangeInput
    errors: [NotFoundError, ValidationError, RateLimitError]
}

structure ConfirmEmailAddressChangeInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    userId: UserId

    @required
    @httpLabel
    emailAddressToken: String
}

@http(method: "POST", uri: "/{accountId}/users/{userId}/data_exports.json")
@tags(["Users"])
@fizzyRetry(maxAttempts: 1)
operation CreateUserDataExport {
    input: CreateUserDataExportInput
    output: CreateUserDataExportOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError, RateLimitError]
}

structure CreateUserDataExportInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    userId: UserId
}

structure CreateUserDataExportOutput {
    @required
    export: DataExport
}

@readonly
@http(method: "GET", uri: "/{accountId}/users/{userId}/data_exports/{exportId}")
@tags(["Users"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation GetUserDataExport {
    input: GetUserDataExportInput
    output: GetUserDataExportOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure GetUserDataExportInput {
    @required
    @httpLabel
    accountId: AccountId

    @required
    @httpLabel
    userId: UserId

    @required
    @httpLabel
    exportId: ExportId
}

structure GetUserDataExportOutput {
    @required
    export: DataExport
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

    /// "member" or "admin". Any other value, including "owner", sets the role to "member" (Users::RolesController#role_params), so a typo demotes.
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
// Pins
// ═══════════════════════════════════════════════════════════════════════════

@readonly
@http(method: "GET", uri: "/{accountId}/my/pins.json")
@tags(["Pins"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
operation ListPins {
    input: ListPinsInput
    output: ListPinsOutput
    errors: [UnauthorizedError]
}

structure ListPinsInput {
    @required
    @httpLabel
    accountId: AccountId
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

/// Lists the board's webhooks. Fizzy pages this list (a Link header with rel="next"); this operation returns the first page.
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

    /// The events to deliver, from: "card_assigned", "card_closed", "card_postponed", "card_auto_postponed", "card_board_changed", "card_published", "card_reopened", "card_sent_back_to_triage", "card_triaged", "card_unassigned" and "comment_created" (Webhook::PERMITTED_ACTIONS). Unknown actions are dropped silently. A webhook created without any receives no deliveries.
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

/// Updates a webhook's name or subscribed actions. Send at least one: the controller expects a `webhook` object, so an empty body is a 400. The URL can't change after creation; delete the webhook and create a new one.
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

    /// The events to deliver, from: "card_assigned", "card_closed", "card_postponed", "card_auto_postponed", "card_board_changed", "card_published", "card_reopened", "card_sent_back_to_triage", "card_triaged", "card_unassigned" and "comment_created" (Webhook::PERMITTED_ACTIONS). Unknown actions are dropped silently. The list replaces the current subscription.
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

@readonly
@http(method: "GET", uri: "/{accountId}/boards/{boardId}/webhooks/{webhookId}/deliveries.json")
@tags(["Webhooks"])
@fizzyRetry(maxAttempts: 3, baseDelayMs: 1000, backoff: "exponential", retryOn: [429, 500, 503])
@fizzyPagination(style: "link", pageParam: "page")
operation ListWebhookDeliveries {
    input: ListWebhookDeliveriesInput
    output: ListWebhookDeliveriesOutput
    errors: [UnauthorizedError, ForbiddenError, NotFoundError]
}

structure ListWebhookDeliveriesInput {
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

structure ListWebhookDeliveriesOutput {
    @required
    deliveries: WebhookDeliveryList
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
