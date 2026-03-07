// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct ListTagOptions: Sendable {
    public var maxItems: Int?

    public init(maxItems: Int? = nil) {
        self.maxItems = maxItems
    }
}


public final class TagsService: BaseService, @unchecked Sendable {
    public func list(accountId: String, options: ListTagOptions? = nil) async throws -> ListResult<Tag> {
        return try await requestPaginated(
            OperationInfo(service: "Tags", operation: "ListTags", resourceType: "tag", isMutation: false),
            path: "/\(accountId)/tags.json",
            paginationOpts: options.flatMap { PaginationOptions(maxItems: $0.maxItems) },
            retryConfig: Metadata.retryConfig(for: "ListTags")
        )
    }
}
