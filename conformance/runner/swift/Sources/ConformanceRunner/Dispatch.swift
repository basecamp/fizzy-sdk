import Fizzy
import Foundation

enum RunnerError: Error, CustomStringConvertible {
    case unknownOperation(String)
    /// A fixture parameter the dispatch table cannot use as written.
    case badParameter(String)

    var description: String {
        switch self {
        case .unknownOperation(let op): "Unknown operation: \(op)"
        case .badParameter(let detail): "Fixture parameter: \(detail)"
        }
    }
}

/// SDK-observed values captured from a dispatched operation.
struct DispatchResult {
    /// True when the SDK truncated a list (maxItems/maxPages cap hit).
    var truncated: Bool? = nil
}

// MARK: - Fixture parameter helpers

/// These throw rather than substituting a default. A missing `boardId` that
/// quietly became `""` would still produce a request the scripted transport
/// answered from the queue — a green test for a call to the wrong resource,
/// which is the false-green class this runner exists to catch.
///
/// Integers are accepted where a string is asked for and rendered with every
/// digit: the fixtures spell ids both ways (`"boardId": 1`, `"userId": "u1"`)
/// and the wire form is the same either way. The reverse coercion is not
/// offered — a string where the SDK takes an `Int` is a fixture bug.
extension Optional where Wrapped == [String: JSON] {
    func stringParam(_ key: String) throws -> String {
        guard let value = self?[key] else {
            throw RunnerError.badParameter("missing parameter \"\(key)\"")
        }
        guard let string = value.wireString else {
            throw RunnerError.badParameter("parameter \"\(key)\" must be a string or integer, got \(value.display)")
        }
        return string
    }

    func intParam(_ key: String) throws -> Int {
        guard let value = self?[key] else {
            throw RunnerError.badParameter("missing integer parameter \"\(key)\"")
        }
        guard let int = value.intValue, let narrowed = Int(exactly: int) else {
            throw RunnerError.badParameter("parameter \"\(key)\" must be an integer, got \(value.display)")
        }
        return narrowed
    }

    func optString(_ key: String) throws -> String? {
        guard let value = self?[key], value != .null else { return nil }
        guard let string = value.wireString else {
            throw RunnerError.badParameter("parameter \"\(key)\" must be a string or integer, got \(value.display)")
        }
        return string
    }

    /// Query parameters arrive as strings (`"page": "2"`), request bodies as
    /// numbers; both are read here.
    func optInt32(_ key: String) throws -> Int32? {
        guard let value = self?[key], value != .null else { return nil }
        let int = value.intValue ?? value.stringValue.flatMap { Int64($0) }
        guard let int, let narrowed = Int32(exactly: int) else {
            throw RunnerError.badParameter("parameter \"\(key)\" must be a 32-bit integer, got \(value.display)")
        }
        return narrowed
    }

    /// Same for booleans: `"include_read": "true"` in a query, `true` in a body.
    func optBool(_ key: String) throws -> Bool? {
        guard let value = self?[key], value != .null else { return nil }
        if let bool = value.boolValue { return bool }
        switch value.stringValue {
        case "true": return true
        case "false": return false
        default:
            throw RunnerError.badParameter("parameter \"\(key)\" must be a boolean, got \(value.display)")
        }
    }

    /// A list, or a single value promoted to a one-element list — the two
    /// spellings the fixtures use for repeated query keys (`column_ids[]`).
    func optStringList(_ key: String) throws -> [String]? {
        guard let value = self?[key], value != .null else { return nil }
        if let single = value.wireString { return [single] }
        guard let array = value.arrayValue else {
            throw RunnerError.badParameter("parameter \"\(key)\" must be a string or an array, got \(value.display)")
        }
        return try array.map { element in
            guard let string = element.wireString else {
                throw RunnerError.badParameter("parameter \"\(key)\" must contain only strings, got \(element.display)")
            }
            return string
        }
    }
}

/// Operations whose dispatch arm threads a `maxItems` cap into the SDK: the
/// ones that return a `ListResult` through `requestPaginated`. Kept beside the
/// backstop in Runner.swift that enforces it, so a fixture setting
/// `configOverrides.maxItems` on any other operation fails instead of
/// paginating unbounded while it believed it had capped the walk.
let operationsHonoringMaxItems: Set<String> = [
    "ListBoards", "ListCards", "ListClosedCards", "ListColumnCards", "ListPostponedCards",
    "ListStreamCards", "SearchCards", "ListActivities", "ListComments", "ListNotifications",
    "ListTags", "ListUsers", "ListWebhookDeliveries",
]

/// The item cap handed to a paginating operation.
///
/// A fixture that queues one page with a Link header but is not about
/// pagination (it asserts `requestCount: 1` and a status) still has to be
/// dispatched through the SDK's auto-paginating list method. Capping the walk
/// at the first page's item count makes `requestPaginated` return before it
/// follows the link — the same single-page trick the Kotlin runner uses. A
/// fixture that IS about pagination (`followsLinks`) gets no cap, so the SDK
/// walks or refuses the link on its own. An explicit `configOverrides.maxItems`
/// wins over both.
private func listCap(_ tc: TestCase) -> Int? {
    tc.configOverrides?.maxItems ?? (tc.followsLinks ? nil : tc.firstPageItemCount)
}

private func result<T: Sendable>(_ list: ListResult<T>) -> DispatchResult {
    DispatchResult(truncated: list.meta.truncated)
}

/// Dispatches the test operation against the SDK's generated services and
/// returns what the SDK observed. Every operation in the route table has an
/// arm, so a new fixture on any of them runs without touching the runner; an
/// operation the SDK does not know fails rather than being skipped.
///
/// Typed dispatch is deliberate. The Go, Ruby, TypeScript and Rust runners
/// drive raw verbs, but the Swift SDK's per-operation retry policy lives in
/// the generated `Metadata` table that only the service methods consult — so
/// only a call through them pins the behaviour the retry and idempotency
/// fixtures state.
func dispatchOperation(_ tc: TestCase, _ client: FizzyClient) async throws -> DispatchResult {
    let pp = tc.pathParams
    let qp = tc.queryParams
    let rb = tc.requestBody
    let account = { try pp.stringParam("accountId") }
    let cardNumber = { try pp.intParam("cardNumber") }
    let boardId = { try pp.stringParam("boardId") }
    let columnId = { try pp.stringParam("columnId") }
    let commentId = { try pp.stringParam("commentId") }
    let userId = { try pp.stringParam("userId") }
    let webhookId = { try pp.stringParam("webhookId") }
    let cap = listCap(tc)

    switch tc.operation {
    // Boards
    case "ListBoards":
        return result(try await client.boards.list(
            accountId: account(), options: cap.map { ListBoardOptions(maxItems: $0) }))
    case "CreateBoard":
        _ = try await client.boards.create(
            accountId: account(),
            req: CreateBoardRequest(
                allAccess: rb.optBool("all_access"),
                autoPostponePeriodInDays: rb.optInt32("auto_postpone_period_in_days"),
                name: rb.stringParam("name"),
                publicDescription: rb.optString("public_description")))
    case "GetBoard":
        _ = try await client.boards.get(accountId: account(), boardId: boardId())
    case "UpdateBoard":
        _ = try await client.boards.update(
            accountId: account(), boardId: boardId(),
            req: UpdateBoardRequest(
                allAccess: rb.optBool("all_access"),
                autoPostponePeriodInDays: rb.optInt32("auto_postpone_period_in_days"),
                name: rb.optString("name"),
                publicDescription: rb.optString("public_description"),
                userIds: rb.optStringList("user_ids")))
    case "DeleteBoard":
        try await client.boards.delete(accountId: account(), boardId: boardId())
    case "ListBoardAccesses":
        _ = try await client.boards.listBoardAccesses(
            accountId: account(), boardId: boardId(),
            options: ListBoardAccessesBoardOptions(page: qp.optInt32("page")))
    case "PublishBoard":
        try await client.boards.publishBoard(accountId: account(), boardId: boardId())
    case "UnpublishBoard":
        try await client.boards.unpublishBoard(accountId: account(), boardId: boardId())

    // Cards
    case "ListCards":
        return result(try await client.cards.list(
            accountId: account(),
            options: ListCardOptions(
                boardIds: qp.optStringList("board_ids[]"),
                tagIds: qp.optStringList("tag_ids[]"),
                assigneeIds: qp.optStringList("assignee_ids[]"),
                creatorIds: qp.optStringList("creator_ids[]"),
                closerIds: qp.optStringList("closer_ids[]"),
                cardIds: qp.optStringList("card_ids[]"),
                columnIds: qp.optStringList("column_ids[]"),
                indexedBy: qp.optString("indexed_by"),
                sortedBy: qp.optString("sorted_by"),
                assignmentStatus: qp.optString("assignment_status"),
                creation: qp.optString("creation"),
                closure: qp.optString("closure"),
                terms: qp.optStringList("terms[]"),
                maxItems: cap)))
    case "CreateCard":
        _ = try await client.cards.create(
            accountId: account(),
            req: CreateCardRequest(
                assigneeIds: rb.optStringList("assignee_ids"),
                boardId: rb.optString("board_id"),
                columnId: rb.optString("column_id"),
                createdAt: rb.optString("created_at"),
                description: rb.optString("description"),
                image: rb.optString("image"),
                lastActiveAt: rb.optString("last_active_at"),
                tagNames: rb.optStringList("tag_names"),
                title: rb.stringParam("title")))
    case "GetCard":
        _ = try await client.cards.get(accountId: account(), cardNumber: cardNumber())
    case "UpdateCard":
        _ = try await client.cards.update(
            accountId: account(), cardNumber: cardNumber(),
            req: UpdateCardRequest(
                columnId: rb.optString("column_id"),
                createdAt: rb.optString("created_at"),
                description: rb.optString("description"),
                image: rb.optString("image"),
                title: rb.optString("title")))
    case "DeleteCard":
        try await client.cards.delete(accountId: account(), cardNumber: cardNumber())
    case "AssignCard":
        try await client.cards.assign(
            accountId: account(), cardNumber: cardNumber(),
            req: AssignCardRequest(assigneeId: rb.stringParam("assignee_id")))
    case "MoveCard":
        _ = try await client.cards.move(
            accountId: account(), cardNumber: cardNumber(),
            req: MoveCardRequest(boardId: rb.stringParam("board_id"), columnId: rb.optString("column_id")))
    case "CloseCard":
        try await client.cards.close(accountId: account(), cardNumber: cardNumber())
    case "ReopenCard":
        try await client.cards.reopen(accountId: account(), cardNumber: cardNumber())
    case "GoldCard":
        try await client.cards.gold(accountId: account(), cardNumber: cardNumber())
    case "UngoldCard":
        try await client.cards.ungold(accountId: account(), cardNumber: cardNumber())
    case "DeleteCardImage":
        try await client.cards.deleteImage(accountId: account(), cardNumber: cardNumber())
    case "PostponeCard":
        try await client.cards.postpone(accountId: account(), cardNumber: cardNumber())
    case "PinCard":
        try await client.cards.pin(accountId: account(), cardNumber: cardNumber())
    case "UnpinCard":
        try await client.cards.unpin(accountId: account(), cardNumber: cardNumber())
    case "PublishCard":
        try await client.cards.publishCard(accountId: account(), cardNumber: cardNumber())
    case "SelfAssignCard":
        try await client.cards.selfAssign(accountId: account(), cardNumber: cardNumber())
    case "TagCard":
        try await client.cards.tag(
            accountId: account(), cardNumber: cardNumber(),
            req: TagCardRequest(tagTitle: rb.stringParam("tag_title")))
    case "TriageCard":
        try await client.cards.triage(
            accountId: account(), cardNumber: cardNumber(),
            req: TriageCardRequest(columnId: rb.optString("column_id")))
    case "UnTriageCard":
        try await client.cards.untriage(accountId: account(), cardNumber: cardNumber())
    case "WatchCard":
        try await client.cards.watch(accountId: account(), cardNumber: cardNumber())
    case "UnwatchCard":
        try await client.cards.unwatch(accountId: account(), cardNumber: cardNumber())
    case "ListStreamCards":
        return result(try await client.cards.listStreamCards(
            accountId: account(), boardId: boardId(),
            options: cap.map { ListStreamCardsCardOptions(maxItems: $0) }))
    case "ListPostponedCards":
        return result(try await client.cards.listPostponedCards(
            accountId: account(), boardId: boardId(),
            options: cap.map { ListPostponedCardsCardOptions(maxItems: $0) }))
    case "ListClosedCards":
        return result(try await client.cards.listClosedCards(
            accountId: account(), boardId: boardId(),
            options: cap.map { ListClosedCardsCardOptions(maxItems: $0) }))
    case "ListColumnCards":
        return result(try await client.cards.listColumnCards(
            accountId: account(), boardId: boardId(), columnId: columnId(),
            options: cap.map { ListColumnCardsCardOptions(maxItems: $0) }))
    case "SearchCards":
        return result(try await client.cards.search(
            accountId: account(), q: qp.stringParam("q"),
            options: cap.map { SearchCardOptions(maxItems: $0) }))
    case "ListActivities":
        return result(try await client.cards.listActivities(
            accountId: account(),
            options: ListActivitiesCardOptions(
                creatorIds: qp.optStringList("creator_ids[]"),
                boardIds: qp.optStringList("board_ids[]"),
                maxItems: cap)))

    // Columns
    case "ListColumns":
        _ = try await client.columns.list(accountId: account(), boardId: boardId())
    case "CreateColumn":
        _ = try await client.columns.create(
            accountId: account(), boardId: boardId(),
            req: CreateColumnRequest(color: rb.optString("color"), name: rb.stringParam("name")))
    case "GetColumn":
        _ = try await client.columns.get(accountId: account(), boardId: boardId(), columnId: columnId())
    case "UpdateColumn":
        _ = try await client.columns.update(
            accountId: account(), boardId: boardId(), columnId: columnId(),
            req: UpdateColumnRequest(color: rb.optString("color"), name: rb.optString("name")))
    case "DeleteColumn":
        try await client.columns.delete(accountId: account(), boardId: boardId(), columnId: columnId())
    case "MoveColumnLeft":
        try await client.miscellaneous.moveColumnLeft(accountId: account(), columnId: columnId())
    case "MoveColumnRight":
        try await client.miscellaneous.moveColumnRight(accountId: account(), columnId: columnId())

    // Comments
    case "ListComments":
        return result(try await client.comments.list(
            accountId: account(), cardNumber: cardNumber(),
            options: cap.map { ListCommentOptions(maxItems: $0) }))
    case "CreateComment":
        _ = try await client.comments.create(
            accountId: account(), cardNumber: cardNumber(),
            req: CreateCommentRequest(body: rb.stringParam("body"), createdAt: rb.optString("created_at")))
    case "GetComment":
        _ = try await client.comments.get(accountId: account(), cardNumber: cardNumber(), commentId: commentId())
    case "UpdateComment":
        _ = try await client.comments.update(
            accountId: account(), cardNumber: cardNumber(), commentId: commentId(),
            req: UpdateCommentRequest(body: rb.stringParam("body")))
    case "DeleteComment":
        try await client.comments.delete(accountId: account(), cardNumber: cardNumber(), commentId: commentId())

    // Reactions
    case "ListCardReactions":
        _ = try await client.reactions.listForCard(accountId: account(), cardNumber: cardNumber())
    case "CreateCardReaction":
        _ = try await client.reactions.createForCard(
            accountId: account(), cardNumber: cardNumber(),
            req: CreateCardReactionRequest(content: rb.stringParam("content")))
    case "DeleteCardReaction":
        try await client.reactions.deleteForCard(
            accountId: account(), cardNumber: cardNumber(), reactionId: pp.stringParam("reactionId"))
    case "ListCommentReactions":
        _ = try await client.reactions.listForComment(
            accountId: account(), cardNumber: cardNumber(), commentId: commentId())
    case "CreateCommentReaction":
        _ = try await client.reactions.createForComment(
            accountId: account(), cardNumber: cardNumber(), commentId: commentId(),
            req: CreateCommentReactionRequest(content: rb.stringParam("content")))
    case "DeleteCommentReaction":
        try await client.reactions.deleteForComment(
            accountId: account(), cardNumber: cardNumber(), commentId: commentId(),
            reactionId: pp.stringParam("reactionId"))

    // Steps
    case "ListSteps":
        _ = try await client.steps.list(accountId: account(), cardNumber: cardNumber())
    case "CreateStep":
        _ = try await client.steps.create(
            accountId: account(), cardNumber: cardNumber(),
            req: CreateStepRequest(completed: rb.optBool("completed"), content: rb.stringParam("content")))
    case "GetStep":
        _ = try await client.steps.get(accountId: account(), cardNumber: cardNumber(), stepId: pp.stringParam("stepId"))
    case "UpdateStep":
        _ = try await client.steps.update(
            accountId: account(), cardNumber: cardNumber(), stepId: pp.stringParam("stepId"),
            req: UpdateStepRequest(completed: rb.optBool("completed"), content: rb.optString("content")))
    case "DeleteStep":
        try await client.steps.delete(accountId: account(), cardNumber: cardNumber(), stepId: pp.stringParam("stepId"))

    // Card read state
    case "MarkCardRead":
        try await client.miscellaneous.markCardRead(accountId: account(), cardNumber: cardNumber())
    case "MarkCardUnread":
        try await client.miscellaneous.markCardUnread(accountId: account(), cardNumber: cardNumber())

    // Tags, pins
    case "ListTags":
        return result(try await client.tags.list(accountId: account(), options: cap.map { ListTagOptions(maxItems: $0) }))
    case "ListPins":
        _ = try await client.pins.list(accountId: account())

    // Devices
    case "RegisterDevice":
        try await client.devices.register(
            accountId: account(),
            req: RegisterDeviceRequest(
                name: rb.optString("name"), platform: rb.stringParam("platform"), token: rb.stringParam("token")))
    case "UnregisterDevice":
        try await client.devices.unregister(accountId: account(), deviceToken: pp.stringParam("deviceToken"))

    // Identity, sessions
    case "GetMyIdentity":
        _ = try await client.identity.me()
    case "UpdateMyTimezone":
        try await client.identity.updateTimezone(
            accountId: account(), req: UpdateMyTimezoneRequest(timezoneName: rb.stringParam("timezone_name")))
    case "CreateSession":
        _ = try await client.sessions.create(req: CreateSessionRequest(emailAddress: rb.stringParam("email_address")))
    case "DestroySession":
        try await client.sessions.destroy()
    case "RedeemMagicLink":
        _ = try await client.sessions.redeemMagicLink(req: RedeemMagicLinkRequest(token: rb.stringParam("token")))
    case "CompleteSignup":
        try await client.sessions.completeSignup(req: CompleteSignupRequest(fullName: rb.stringParam("full_name")))
    case "CompleteJoin":
        try await client.sessions.completeJoin(req: CompleteJoinRequest(name: rb.stringParam("name")))

    // Notifications
    case "ListNotifications":
        return result(try await client.notifications.list(
            accountId: account(),
            options: ListNotificationOptions(read: qp.optBool("read"), maxItems: cap)))
    case "GetNotificationTray":
        _ = try await client.notifications.tray(
            accountId: account(), options: TrayNotificationOptions(includeRead: qp.optBool("include_read")))
    case "BulkReadNotifications":
        try await client.notifications.bulkRead(
            accountId: account(),
            req: BulkReadNotificationsRequest(notificationIds: rb.optStringList("notification_ids")))
    case "ReadNotification":
        try await client.notifications.read(accountId: account(), notificationId: pp.stringParam("notificationId"))
    case "UnreadNotification":
        try await client.notifications.unread(accountId: account(), notificationId: pp.stringParam("notificationId"))
    case "GetNotificationSettings":
        _ = try await client.miscellaneous.notificationSettings(accountId: account())
    case "UpdateNotificationSettings":
        try await client.miscellaneous.updateNotificationSettings(
            accountId: account(),
            req: UpdateNotificationSettingsRequest(bundleEmailFrequency: rb.optString("bundle_email_frequency")))

    // Uploads
    case "CreateDirectUpload":
        _ = try await client.uploads.createDirect(
            accountId: account(),
            req: CreateDirectUploadRequest(
                byteSize: rb.intParam("byte_size"),
                checksum: rb.stringParam("checksum"),
                contentType: rb.stringParam("content_type"),
                filename: rb.stringParam("filename")))

    // Users
    case "ListUsers":
        return result(try await client.users.list(accountId: account(), options: cap.map { ListUserOptions(maxItems: $0) }))
    case "GetUser":
        _ = try await client.users.get(accountId: account(), userId: userId())
    case "UpdateUser":
        _ = try await client.users.update(
            accountId: account(), userId: userId(), req: UpdateUserRequest(name: rb.optString("name")))
    case "DeactivateUser":
        try await client.users.deactivate(accountId: account(), userId: userId())
    case "RequestEmailAddressChange":
        try await client.users.requestEmailAddressChange(
            accountId: account(), userId: userId(),
            req: RequestEmailAddressChangeRequest(emailAddress: rb.stringParam("email_address")))
    case "ConfirmEmailAddressChange":
        try await client.users.confirmEmailAddressChange(
            accountId: account(), userId: userId(), emailAddressToken: pp.stringParam("emailAddressToken"))
    case "CreateUserDataExport":
        _ = try await client.users.createUserDataExport(accountId: account(), userId: userId())
    case "GetUserDataExport":
        _ = try await client.users.userDataExport(
            accountId: account(), userId: userId(), exportId: pp.stringParam("exportId"))
    case "DeleteUserAvatar":
        try await client.miscellaneous.deleteUserAvatar(accountId: account(), userId: userId())
    case "CreatePushSubscription":
        try await client.miscellaneous.createPushSubscription(
            accountId: account(), userId: userId(),
            req: CreatePushSubscriptionRequest(
                authKey: rb.stringParam("auth_key"),
                endpoint: rb.stringParam("endpoint"),
                p256dhKey: rb.stringParam("p256dh_key")))
    case "DeletePushSubscription":
        try await client.miscellaneous.deletePushSubscription(
            accountId: account(), userId: userId(), pushSubscriptionId: pp.stringParam("pushSubscriptionId"))
    case "UpdateUserRole":
        try await client.miscellaneous.updateUserRole(
            accountId: account(), userId: userId(), req: UpdateUserRoleRequest(role: rb.stringParam("role")))

    // Webhooks
    case "ListWebhooks":
        _ = try await client.webhooks.list(accountId: account(), boardId: boardId())
    case "CreateWebhook":
        _ = try await client.webhooks.create(
            accountId: account(), boardId: boardId(),
            req: CreateWebhookRequest(
                name: rb.stringParam("name"),
                subscribedActions: rb.optStringList("subscribed_actions"),
                url: rb.stringParam("url")))
    case "GetWebhook":
        _ = try await client.webhooks.get(accountId: account(), boardId: boardId(), webhookId: webhookId())
    case "UpdateWebhook":
        _ = try await client.webhooks.update(
            accountId: account(), boardId: boardId(), webhookId: webhookId(),
            req: UpdateWebhookRequest(
                name: rb.optString("name"),
                subscribedActions: rb.optStringList("subscribed_actions"),
                url: rb.optString("url")))
    case "DeleteWebhook":
        try await client.webhooks.delete(accountId: account(), boardId: boardId(), webhookId: webhookId())
    case "ActivateWebhook":
        try await client.webhooks.activate(accountId: account(), boardId: boardId(), webhookId: webhookId())
    case "ListWebhookDeliveries":
        return result(try await client.webhooks.listWebhookDeliveries(
            accountId: account(), boardId: boardId(), webhookId: webhookId(),
            options: cap.map { ListWebhookDeliveriesWebhookOptions(maxItems: $0) }))

    // Access tokens
    case "ListAccessTokens":
        _ = try await client.miscellaneous.listAccessTokens()
    case "CreateAccessToken":
        _ = try await client.miscellaneous.createAccessToken(
            req: CreateAccessTokenRequest(
                description: rb.stringParam("description"), permission: rb.stringParam("permission")))
    case "DeleteAccessToken":
        try await client.miscellaneous.deleteAccessToken(accessTokenId: pp.stringParam("accessTokenId"))

    // Account
    case "GetAccountSettings":
        _ = try await client.miscellaneous.accountSettings(accountId: account())
    case "UpdateAccountSettings":
        try await client.miscellaneous.updateAccountSettings(
            accountId: account(), req: UpdateAccountSettingsRequest(name: rb.optString("name")))
    case "UpdateAccountEntropy":
        _ = try await client.miscellaneous.updateAccountEntropy(
            accountId: account(),
            req: UpdateAccountEntropyRequest(autoPostponePeriodInDays: rb.optInt32("auto_postpone_period_in_days")))
    case "CreateAccountExport":
        _ = try await client.miscellaneous.createAccountExport(accountId: account())
    case "GetAccountExport":
        _ = try await client.miscellaneous.accountExport(accountId: account(), exportId: pp.stringParam("exportId"))
    case "GetJoinCode":
        _ = try await client.miscellaneous.joinCode(accountId: account())
    case "UpdateJoinCode":
        try await client.miscellaneous.updateJoinCode(
            accountId: account(), req: UpdateJoinCodeRequest(usageLimit: rb.optInt32("usage_limit")))
    case "ResetJoinCode":
        try await client.miscellaneous.resetJoinCode(accountId: account())
    case "UpdateBoardEntropy":
        _ = try await client.miscellaneous.updateBoardEntropy(
            accountId: account(), boardId: boardId(),
            req: UpdateBoardEntropyRequest(autoPostponePeriodInDays: rb.optInt32("auto_postpone_period_in_days")))
    case "UpdateBoardInvolvement":
        try await client.miscellaneous.updateBoardInvolvement(
            accountId: account(), boardId: boardId(),
            req: UpdateBoardInvolvementRequest(involvement: rb.optString("involvement")))

    default:
        throw RunnerError.unknownOperation(tc.operation)
    }
    return DispatchResult()
}
