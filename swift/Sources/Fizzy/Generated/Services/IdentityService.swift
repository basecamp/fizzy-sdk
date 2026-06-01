// @generated from OpenAPI spec — do not edit directly
import Foundation

public final class IdentityService: BaseService, @unchecked Sendable {
    public func me() async throws -> Identity {
        return try await request(
            OperationInfo(service: "Identity", operation: "GetMyIdentity", resourceType: "my_identity", isMutation: false),
            method: "GET",
            path: "/my/identity.json",
            retryConfig: Metadata.retryConfig(for: "GetMyIdentity")
        )
    }

    public func updateTimezone(accountId: String, req: UpdateMyTimezoneRequest) async throws {
        try await requestVoid(
            OperationInfo(service: "Identity", operation: "UpdateMyTimezone", resourceType: "my_timezone", isMutation: true),
            method: "PATCH",
            path: "/\(accountId)/my/timezone.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateMyTimezone")
        )
    }
}
