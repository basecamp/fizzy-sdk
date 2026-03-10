// @generated from OpenAPI spec — do not edit directly
import Foundation

public final class MiscellaneousService: BaseService, @unchecked Sendable {
    public func createAccessToken(req: CreateAccessTokenRequest) async throws -> AccessToken {
        return try await request(
            OperationInfo(service: "Miscellaneous", operation: "CreateAccessToken", resourceType: "access_token", isMutation: true),
            method: "POST",
            path: "/my/access_tokens.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "CreateAccessToken")
        )
    }

    public func createAccountExport(accountId: String) async throws -> AccountExport {
        return try await request(
            OperationInfo(service: "Miscellaneous", operation: "CreateAccountExport", resourceType: "account_export", isMutation: true),
            method: "POST",
            path: "/\(accountId)/account/exports.json",
            retryConfig: Metadata.retryConfig(for: "CreateAccountExport")
        )
    }

    public func createPushSubscription(accountId: String, userId: String, req: CreatePushSubscriptionRequest) async throws {
        try await requestVoid(
            OperationInfo(service: "Miscellaneous", operation: "CreatePushSubscription", resourceType: "push_subscription", isMutation: true),
            method: "POST",
            path: "/\(accountId)/users/\(userId)/push_subscriptions.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "CreatePushSubscription")
        )
    }

    public func deleteAccessToken(accessTokenId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Miscellaneous", operation: "DeleteAccessToken", resourceType: "access_token", isMutation: true),
            method: "DELETE",
            path: "/my/access_tokens/\(accessTokenId)",
            retryConfig: Metadata.retryConfig(for: "DeleteAccessToken")
        )
    }

    public func deletePushSubscription(accountId: String, userId: String, pushSubscriptionId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Miscellaneous", operation: "DeletePushSubscription", resourceType: "push_subscription", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/users/\(userId)/push_subscriptions/\(pushSubscriptionId)",
            retryConfig: Metadata.retryConfig(for: "DeletePushSubscription")
        )
    }

    public func deleteUserAvatar(accountId: String, userId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Miscellaneous", operation: "DeleteUserAvatar", resourceType: "user_avatar", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/users/\(userId)/avatar",
            retryConfig: Metadata.retryConfig(for: "DeleteUserAvatar")
        )
    }

    public func accountExport(accountId: String, exportId: String) async throws -> AccountExport {
        return try await request(
            OperationInfo(service: "Miscellaneous", operation: "GetAccountExport", resourceType: "account_export", isMutation: false),
            method: "GET",
            path: "/\(accountId)/account/exports/\(exportId)",
            retryConfig: Metadata.retryConfig(for: "GetAccountExport")
        )
    }

    public func accountSettings(accountId: String) async throws -> AccountSettings {
        return try await request(
            OperationInfo(service: "Miscellaneous", operation: "GetAccountSettings", resourceType: "account_setting", isMutation: false),
            method: "GET",
            path: "/\(accountId)/account/settings.json",
            retryConfig: Metadata.retryConfig(for: "GetAccountSettings")
        )
    }

    public func joinCode(accountId: String) async throws -> JoinCode {
        return try await request(
            OperationInfo(service: "Miscellaneous", operation: "GetJoinCode", resourceType: "join_code", isMutation: false),
            method: "GET",
            path: "/\(accountId)/account/join_code.json",
            retryConfig: Metadata.retryConfig(for: "GetJoinCode")
        )
    }

    public func notificationSettings(accountId: String) async throws -> NotificationSettings {
        return try await request(
            OperationInfo(service: "Miscellaneous", operation: "GetNotificationSettings", resourceType: "notification_setting", isMutation: false),
            method: "GET",
            path: "/\(accountId)/notifications/settings.json",
            retryConfig: Metadata.retryConfig(for: "GetNotificationSettings")
        )
    }

    public func listAccessTokens() async throws -> [AccessToken] {
        return try await request(
            OperationInfo(service: "Miscellaneous", operation: "ListAccessTokens", resourceType: "access_token", isMutation: false),
            method: "GET",
            path: "/my/access_tokens.json",
            retryConfig: Metadata.retryConfig(for: "ListAccessTokens")
        )
    }

    public func markCardRead(accountId: String, cardNumber: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Miscellaneous", operation: "MarkCardRead", resourceType: "resource", isMutation: true),
            method: "POST",
            path: "/\(accountId)/cards/\(cardNumber)/reading.json",
            retryConfig: Metadata.retryConfig(for: "MarkCardRead")
        )
    }

    public func markCardUnread(accountId: String, cardNumber: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Miscellaneous", operation: "MarkCardUnread", resourceType: "resource", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/cards/\(cardNumber)/reading.json",
            retryConfig: Metadata.retryConfig(for: "MarkCardUnread")
        )
    }

    public func moveColumnLeft(accountId: String, columnId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Miscellaneous", operation: "MoveColumnLeft", resourceType: "column_left", isMutation: true),
            method: "POST",
            path: "/\(accountId)/columns/\(columnId)/left_position.json",
            retryConfig: Metadata.retryConfig(for: "MoveColumnLeft")
        )
    }

    public func moveColumnRight(accountId: String, columnId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Miscellaneous", operation: "MoveColumnRight", resourceType: "column_right", isMutation: true),
            method: "POST",
            path: "/\(accountId)/columns/\(columnId)/right_position.json",
            retryConfig: Metadata.retryConfig(for: "MoveColumnRight")
        )
    }

    public func resetJoinCode(accountId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Miscellaneous", operation: "ResetJoinCode", resourceType: "resource", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/account/join_code.json",
            retryConfig: Metadata.retryConfig(for: "ResetJoinCode")
        )
    }

    public func updateAccountEntropy(accountId: String, req: UpdateAccountEntropyRequest) async throws -> AccountSettings {
        return try await request(
            OperationInfo(service: "Miscellaneous", operation: "UpdateAccountEntropy", resourceType: "account_entropy", isMutation: true),
            method: "PUT",
            path: "/\(accountId)/account/entropy.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateAccountEntropy")
        )
    }

    public func updateAccountSettings(accountId: String, req: UpdateAccountSettingsRequest) async throws {
        try await requestVoid(
            OperationInfo(service: "Miscellaneous", operation: "UpdateAccountSettings", resourceType: "account_setting", isMutation: true),
            method: "PATCH",
            path: "/\(accountId)/account/settings.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateAccountSettings")
        )
    }

    public func updateBoardEntropy(accountId: String, boardId: String, req: UpdateBoardEntropyRequest) async throws -> Board {
        return try await request(
            OperationInfo(service: "Miscellaneous", operation: "UpdateBoardEntropy", resourceType: "board_entropy", isMutation: true),
            method: "PUT",
            path: "/\(accountId)/boards/\(boardId)/entropy.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateBoardEntropy")
        )
    }

    public func updateBoardInvolvement(accountId: String, boardId: String, req: UpdateBoardInvolvementRequest) async throws {
        try await requestVoid(
            OperationInfo(service: "Miscellaneous", operation: "UpdateBoardInvolvement", resourceType: "board_involvement", isMutation: true),
            method: "PATCH",
            path: "/\(accountId)/boards/\(boardId)/involvement.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateBoardInvolvement")
        )
    }

    public func updateJoinCode(accountId: String, req: UpdateJoinCodeRequest) async throws {
        try await requestVoid(
            OperationInfo(service: "Miscellaneous", operation: "UpdateJoinCode", resourceType: "join_code", isMutation: true),
            method: "PATCH",
            path: "/\(accountId)/account/join_code.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateJoinCode")
        )
    }

    public func updateNotificationSettings(accountId: String, req: UpdateNotificationSettingsRequest) async throws {
        try await requestVoid(
            OperationInfo(service: "Miscellaneous", operation: "UpdateNotificationSettings", resourceType: "notification_setting", isMutation: true),
            method: "PATCH",
            path: "/\(accountId)/notifications/settings.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateNotificationSettings")
        )
    }

    public func updateUserRole(accountId: String, userId: String, req: UpdateUserRoleRequest) async throws {
        try await requestVoid(
            OperationInfo(service: "Miscellaneous", operation: "UpdateUserRole", resourceType: "user_role", isMutation: true),
            method: "PATCH",
            path: "/\(accountId)/users/\(userId)/role.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateUserRole")
        )
    }
}
