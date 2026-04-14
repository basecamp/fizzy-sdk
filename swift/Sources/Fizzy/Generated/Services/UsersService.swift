// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct ListUserOptions: Sendable {
    public var maxItems: Int?

    public init(maxItems: Int? = nil) {
        self.maxItems = maxItems
    }
}


public final class UsersService: BaseService, @unchecked Sendable {
    public func confirmEmailAddressChange(accountId: String, userId: String, emailAddressToken: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Users", operation: "ConfirmEmailAddressChange", resourceType: "resource", isMutation: true),
            method: "POST",
            path: "/\(accountId)/users/\(userId)/email_addresses/\(emailAddressToken)/confirmation.json",
            retryConfig: Metadata.retryConfig(for: "ConfirmEmailAddressChange")
        )
    }

    public func createUserDataExport(accountId: String, userId: String) async throws -> DataExport {
        return try await request(
            OperationInfo(service: "Users", operation: "CreateUserDataExport", resourceType: "user_data_export", isMutation: true),
            method: "POST",
            path: "/\(accountId)/users/\(userId)/data_exports.json",
            retryConfig: Metadata.retryConfig(for: "CreateUserDataExport")
        )
    }

    public func deactivate(accountId: String, userId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Users", operation: "DeactivateUser", resourceType: "user", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/users/\(userId)",
            retryConfig: Metadata.retryConfig(for: "DeactivateUser")
        )
    }

    public func get(accountId: String, userId: String) async throws -> User {
        return try await request(
            OperationInfo(service: "Users", operation: "GetUser", resourceType: "user", isMutation: false),
            method: "GET",
            path: "/\(accountId)/users/\(userId)",
            retryConfig: Metadata.retryConfig(for: "GetUser")
        )
    }

    public func userDataExport(accountId: String, userId: String, exportId: String) async throws -> DataExport {
        return try await request(
            OperationInfo(service: "Users", operation: "GetUserDataExport", resourceType: "user_data_export", isMutation: false),
            method: "GET",
            path: "/\(accountId)/users/\(userId)/data_exports/\(exportId)",
            retryConfig: Metadata.retryConfig(for: "GetUserDataExport")
        )
    }

    public func list(accountId: String, options: ListUserOptions? = nil) async throws -> ListResult<User> {
        return try await requestPaginated(
            OperationInfo(service: "Users", operation: "ListUsers", resourceType: "user", isMutation: false),
            path: "/\(accountId)/users.json",
            paginationOpts: options.flatMap { PaginationOptions(maxItems: $0.maxItems) },
            retryConfig: Metadata.retryConfig(for: "ListUsers")
        )
    }

    public func requestEmailAddressChange(accountId: String, userId: String, req: RequestEmailAddressChangeRequest) async throws {
        try await requestVoid(
            OperationInfo(service: "Users", operation: "RequestEmailAddressChange", resourceType: "resource", isMutation: true),
            method: "POST",
            path: "/\(accountId)/users/\(userId)/email_addresses.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "RequestEmailAddressChange")
        )
    }

    public func update(accountId: String, userId: String, req: UpdateUserRequest) async throws -> User {
        return try await request(
            OperationInfo(service: "Users", operation: "UpdateUser", resourceType: "user", isMutation: true),
            method: "PATCH",
            path: "/\(accountId)/users/\(userId)",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateUser")
        )
    }
}
