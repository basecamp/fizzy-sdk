// @generated from OpenAPI spec — do not edit directly
import Foundation

public final class WebhooksService: BaseService, @unchecked Sendable {
    public func activate(accountId: String, boardId: Int, webhookId: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Webhooks", operation: "ActivateWebhook", resourceType: "webhook", isMutation: true, boardId: boardId, resourceId: webhookId),
            method: "POST",
            path: "/\(accountId)/boards/\(boardId)/webhooks/\(webhookId)/activation.json",
            retryConfig: Metadata.retryConfig(for: "ActivateWebhook")
        )
    }

    public func create(accountId: String, boardId: Int, req: CreateWebhookRequest) async throws -> Webhook {
        return try await request(
            OperationInfo(service: "Webhooks", operation: "CreateWebhook", resourceType: "webhook", isMutation: true, boardId: boardId),
            method: "POST",
            path: "/\(accountId)/boards/\(boardId)/webhooks.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "CreateWebhook")
        )
    }

    public func delete(accountId: String, boardId: Int, webhookId: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Webhooks", operation: "DeleteWebhook", resourceType: "webhook", isMutation: true, boardId: boardId, resourceId: webhookId),
            method: "DELETE",
            path: "/\(accountId)/boards/\(boardId)/webhooks/\(webhookId)",
            retryConfig: Metadata.retryConfig(for: "DeleteWebhook")
        )
    }

    public func get(accountId: String, boardId: Int, webhookId: Int) async throws -> Webhook {
        return try await request(
            OperationInfo(service: "Webhooks", operation: "GetWebhook", resourceType: "webhook", isMutation: false, boardId: boardId, resourceId: webhookId),
            method: "GET",
            path: "/\(accountId)/boards/\(boardId)/webhooks/\(webhookId)",
            retryConfig: Metadata.retryConfig(for: "GetWebhook")
        )
    }

    public func list(accountId: String, boardId: Int) async throws -> [Webhook] {
        return try await request(
            OperationInfo(service: "Webhooks", operation: "ListWebhooks", resourceType: "webhook", isMutation: false, boardId: boardId),
            method: "GET",
            path: "/\(accountId)/boards/\(boardId)/webhooks.json",
            retryConfig: Metadata.retryConfig(for: "ListWebhooks")
        )
    }

    public func update(accountId: String, boardId: Int, webhookId: Int, req: UpdateWebhookRequest) async throws -> Webhook {
        return try await request(
            OperationInfo(service: "Webhooks", operation: "UpdateWebhook", resourceType: "webhook", isMutation: true, boardId: boardId, resourceId: webhookId),
            method: "PATCH",
            path: "/\(accountId)/boards/\(boardId)/webhooks/\(webhookId)",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateWebhook")
        )
    }
}
