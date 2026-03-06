// @generated from OpenAPI spec — do not edit directly
import Foundation

public final class UploadsService: BaseService, @unchecked Sendable {
    public func createDirect(accountId: String, req: CreateDirectUploadRequest) async throws -> DirectUpload {
        return try await request(
            OperationInfo(service: "Uploads", operation: "CreateDirectUpload", resourceType: "direct_upload", isMutation: true),
            method: "POST",
            path: "/\(accountId)/rails/active_storage/direct_uploads",
            body: req,
            retryConfig: Metadata.retryConfig(for: "CreateDirectUpload")
        )
    }
}
