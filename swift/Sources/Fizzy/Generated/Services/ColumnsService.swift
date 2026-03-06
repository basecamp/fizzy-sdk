// @generated from OpenAPI spec — do not edit directly
import Foundation

public final class ColumnsService: BaseService, @unchecked Sendable {
    public func create(accountId: String, boardId: Int, req: CreateColumnRequest) async throws -> Column {
        return try await request(
            OperationInfo(service: "Columns", operation: "CreateColumn", resourceType: "column", isMutation: true, boardId: boardId),
            method: "POST",
            path: "/\(accountId)/boards/\(boardId)/columns.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "CreateColumn")
        )
    }

    public func get(accountId: String, boardId: Int, columnId: Int) async throws -> Column {
        return try await request(
            OperationInfo(service: "Columns", operation: "GetColumn", resourceType: "column", isMutation: false, boardId: boardId, resourceId: columnId),
            method: "GET",
            path: "/\(accountId)/boards/\(boardId)/columns/\(columnId)",
            retryConfig: Metadata.retryConfig(for: "GetColumn")
        )
    }

    public func list(accountId: String, boardId: Int) async throws -> [Column] {
        return try await request(
            OperationInfo(service: "Columns", operation: "ListColumns", resourceType: "column", isMutation: false, boardId: boardId),
            method: "GET",
            path: "/\(accountId)/boards/\(boardId)/columns.json",
            retryConfig: Metadata.retryConfig(for: "ListColumns")
        )
    }

    public func update(accountId: String, boardId: Int, columnId: Int, req: UpdateColumnRequest) async throws -> Column {
        return try await request(
            OperationInfo(service: "Columns", operation: "UpdateColumn", resourceType: "column", isMutation: true, boardId: boardId, resourceId: columnId),
            method: "PATCH",
            path: "/\(accountId)/boards/\(boardId)/columns/\(columnId)",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateColumn")
        )
    }
}
