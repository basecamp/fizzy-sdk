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
}
