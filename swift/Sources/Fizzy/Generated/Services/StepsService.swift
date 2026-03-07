// @generated from OpenAPI spec — do not edit directly
import Foundation

public final class StepsService: BaseService, @unchecked Sendable {
    public func create(accountId: String, cardNumber: Int, req: CreateStepRequest) async throws -> Step {
        return try await request(
            OperationInfo(service: "Steps", operation: "CreateStep", resourceType: "step", isMutation: true),
            method: "POST",
            path: "/\(accountId)/cards/\(cardNumber)/steps.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "CreateStep")
        )
    }

    public func delete(accountId: String, cardNumber: Int, stepId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Steps", operation: "DeleteStep", resourceType: "step", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/cards/\(cardNumber)/steps/\(stepId)",
            retryConfig: Metadata.retryConfig(for: "DeleteStep")
        )
    }

    public func get(accountId: String, cardNumber: Int, stepId: String) async throws -> Step {
        return try await request(
            OperationInfo(service: "Steps", operation: "GetStep", resourceType: "step", isMutation: false),
            method: "GET",
            path: "/\(accountId)/cards/\(cardNumber)/steps/\(stepId)",
            retryConfig: Metadata.retryConfig(for: "GetStep")
        )
    }

    public func update(accountId: String, cardNumber: Int, stepId: String, req: UpdateStepRequest) async throws -> Step {
        return try await request(
            OperationInfo(service: "Steps", operation: "UpdateStep", resourceType: "step", isMutation: true),
            method: "PATCH",
            path: "/\(accountId)/cards/\(cardNumber)/steps/\(stepId)",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateStep")
        )
    }
}
