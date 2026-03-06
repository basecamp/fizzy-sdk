// @generated from OpenAPI spec — do not edit directly
import Foundation

public final class TagsService: BaseService, @unchecked Sendable {
    public func list(accountId: String) async throws -> [Tag] {
        return try await request(
            OperationInfo(service: "Tags", operation: "ListTags", resourceType: "tag", isMutation: false),
            method: "GET",
            path: "/\(accountId)/tags.json",
            retryConfig: Metadata.retryConfig(for: "ListTags")
        )
    }
}
