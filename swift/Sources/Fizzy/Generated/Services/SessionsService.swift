// @generated from OpenAPI spec — do not edit directly
import Foundation

public final class SessionsService: BaseService, @unchecked Sendable {
    public func completeSignup(req: CompleteSignupRequest) async throws -> User {
        return try await request(
            OperationInfo(service: "Sessions", operation: "CompleteSignup", resourceType: "signup", isMutation: true),
            method: "POST",
            path: "/signup/completion.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "CompleteSignup")
        )
    }

    public func create(req: CreateSessionRequest) async throws -> PendingAuthentication {
        return try await request(
            OperationInfo(service: "Sessions", operation: "CreateSession", resourceType: "session", isMutation: true),
            method: "POST",
            path: "/session.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "CreateSession")
        )
    }

    public func destroy() async throws {
        try await requestVoid(
            OperationInfo(service: "Sessions", operation: "DestroySession", resourceType: "session", isMutation: true),
            method: "DELETE",
            path: "/session.json",
            retryConfig: Metadata.retryConfig(for: "DestroySession")
        )
    }

    public func redeemMagicLink(req: RedeemMagicLinkRequest) async throws -> SessionAuthorization {
        return try await request(
            OperationInfo(service: "Sessions", operation: "RedeemMagicLink", resourceType: "magic_link", isMutation: true),
            method: "POST",
            path: "/session/magic_link.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "RedeemMagicLink")
        )
    }
}
