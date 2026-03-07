// @generated from OpenAPI spec — do not edit directly
import Foundation

public final class ReactionsService: BaseService, @unchecked Sendable {
    public func createForCard(accountId: String, cardNumber: Int, req: CreateCardReactionRequest) async throws -> Reaction {
        return try await request(
            OperationInfo(service: "Reactions", operation: "CreateCardReaction", resourceType: "card_reaction", isMutation: true),
            method: "POST",
            path: "/\(accountId)/cards/\(cardNumber)/reactions.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "CreateCardReaction")
        )
    }

    public func createForComment(accountId: String, cardNumber: Int, commentId: String, req: CreateCommentReactionRequest) async throws -> Reaction {
        return try await request(
            OperationInfo(service: "Reactions", operation: "CreateCommentReaction", resourceType: "comment_reaction", isMutation: true),
            method: "POST",
            path: "/\(accountId)/cards/\(cardNumber)/comments/\(commentId)/reactions.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "CreateCommentReaction")
        )
    }

    public func deleteForCard(accountId: String, cardNumber: Int, reactionId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Reactions", operation: "DeleteCardReaction", resourceType: "card_reaction", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/cards/\(cardNumber)/reactions/\(reactionId)",
            retryConfig: Metadata.retryConfig(for: "DeleteCardReaction")
        )
    }

    public func deleteForComment(accountId: String, cardNumber: Int, commentId: String, reactionId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Reactions", operation: "DeleteCommentReaction", resourceType: "comment_reaction", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/cards/\(cardNumber)/comments/\(commentId)/reactions/\(reactionId)",
            retryConfig: Metadata.retryConfig(for: "DeleteCommentReaction")
        )
    }

    public func listForCard(accountId: String, cardNumber: Int) async throws -> [Reaction] {
        return try await request(
            OperationInfo(service: "Reactions", operation: "ListCardReactions", resourceType: "card_reaction", isMutation: false),
            method: "GET",
            path: "/\(accountId)/cards/\(cardNumber)/reactions.json",
            retryConfig: Metadata.retryConfig(for: "ListCardReactions")
        )
    }

    public func listForComment(accountId: String, cardNumber: Int, commentId: String) async throws -> [Reaction] {
        return try await request(
            OperationInfo(service: "Reactions", operation: "ListCommentReactions", resourceType: "comment_reaction", isMutation: false),
            method: "GET",
            path: "/\(accountId)/cards/\(cardNumber)/comments/\(commentId)/reactions.json",
            retryConfig: Metadata.retryConfig(for: "ListCommentReactions")
        )
    }
}
