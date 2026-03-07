// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct ListCommentOptions: Sendable {
    public var maxItems: Int?

    public init(maxItems: Int? = nil) {
        self.maxItems = maxItems
    }
}


public final class CommentsService: BaseService, @unchecked Sendable {
    public func create(accountId: String, cardNumber: Int, req: CreateCommentRequest) async throws -> Comment {
        return try await request(
            OperationInfo(service: "Comments", operation: "CreateComment", resourceType: "comment", isMutation: true),
            method: "POST",
            path: "/\(accountId)/cards/\(cardNumber)/comments.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "CreateComment")
        )
    }

    public func delete(accountId: String, cardNumber: Int, commentId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Comments", operation: "DeleteComment", resourceType: "comment", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/cards/\(cardNumber)/comments/\(commentId)",
            retryConfig: Metadata.retryConfig(for: "DeleteComment")
        )
    }

    public func get(accountId: String, cardNumber: Int, commentId: String) async throws -> Comment {
        return try await request(
            OperationInfo(service: "Comments", operation: "GetComment", resourceType: "comment", isMutation: false),
            method: "GET",
            path: "/\(accountId)/cards/\(cardNumber)/comments/\(commentId)",
            retryConfig: Metadata.retryConfig(for: "GetComment")
        )
    }

    public func list(accountId: String, cardNumber: Int, options: ListCommentOptions? = nil) async throws -> ListResult<Comment> {
        return try await requestPaginated(
            OperationInfo(service: "Comments", operation: "ListComments", resourceType: "comment", isMutation: false),
            path: "/\(accountId)/cards/\(cardNumber)/comments.json",
            paginationOpts: options.flatMap { PaginationOptions(maxItems: $0.maxItems) },
            retryConfig: Metadata.retryConfig(for: "ListComments")
        )
    }

    public func update(accountId: String, cardNumber: Int, commentId: String, req: UpdateCommentRequest) async throws -> Comment {
        return try await request(
            OperationInfo(service: "Comments", operation: "UpdateComment", resourceType: "comment", isMutation: true),
            method: "PATCH",
            path: "/\(accountId)/cards/\(cardNumber)/comments/\(commentId)",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateComment")
        )
    }
}
