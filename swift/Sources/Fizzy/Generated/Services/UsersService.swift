// @generated from OpenAPI spec — do not edit directly
import Foundation

public final class UsersService: BaseService, @unchecked Sendable {
    public func deactivate(accountId: String, userId: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Users", operation: "DeactivateUser", resourceType: "user", isMutation: true, resourceId: userId),
            method: "DELETE",
            path: "/\(accountId)/users/\(userId)",
            retryConfig: Metadata.retryConfig(for: "DeactivateUser")
        )
    }

    public func get(accountId: String, userId: Int) async throws -> User {
        return try await request(
            OperationInfo(service: "Users", operation: "GetUser", resourceType: "user", isMutation: false, resourceId: userId),
            method: "GET",
            path: "/\(accountId)/users/\(userId)",
            retryConfig: Metadata.retryConfig(for: "GetUser")
        )
    }

    public func list(accountId: String) async throws -> [User] {
        return try await request(
            OperationInfo(service: "Users", operation: "ListUsers", resourceType: "user", isMutation: false),
            method: "GET",
            path: "/\(accountId)/users.json",
            retryConfig: Metadata.retryConfig(for: "ListUsers")
        )
    }

    public func update(accountId: String, userId: Int, req: UpdateUserRequest) async throws -> User {
        return try await request(
            OperationInfo(service: "Users", operation: "UpdateUser", resourceType: "user", isMutation: true, resourceId: userId),
            method: "PATCH",
            path: "/\(accountId)/users/\(userId)",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateUser")
        )
    }
}
