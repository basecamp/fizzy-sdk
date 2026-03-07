// @generated from OpenAPI spec — do not edit directly
import Foundation

public final class ColumnsService: BaseService, @unchecked Sendable {
    public func create(accountId: String, boardId: String, req: CreateColumnRequest) async throws -> Column {
        return try await request(
            OperationInfo(service: "Columns", operation: "CreateColumn", resourceType: "column", isMutation: true),
            method: "POST",
            path: "/\(accountId)/boards/\(boardId)/columns.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "CreateColumn")
        )
    }

    public func delete(accountId: String, boardId: String, columnId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Columns", operation: "DeleteColumn", resourceType: "column", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/boards/\(boardId)/columns/\(columnId)",
            retryConfig: Metadata.retryConfig(for: "DeleteColumn")
        )
    }

    public func get(accountId: String, boardId: String, columnId: String) async throws -> Column {
        return try await request(
            OperationInfo(service: "Columns", operation: "GetColumn", resourceType: "column", isMutation: false),
            method: "GET",
            path: "/\(accountId)/boards/\(boardId)/columns/\(columnId)",
            retryConfig: Metadata.retryConfig(for: "GetColumn")
        )
    }

    public func list(accountId: String, boardId: String) async throws -> [Column] {
        return try await request(
            OperationInfo(service: "Columns", operation: "ListColumns", resourceType: "column", isMutation: false),
            method: "GET",
            path: "/\(accountId)/boards/\(boardId)/columns.json",
            retryConfig: Metadata.retryConfig(for: "ListColumns")
        )
    }

    public func update(accountId: String, boardId: String, columnId: String, req: UpdateColumnRequest) async throws -> Column {
        return try await request(
            OperationInfo(service: "Columns", operation: "UpdateColumn", resourceType: "column", isMutation: true),
            method: "PATCH",
            path: "/\(accountId)/boards/\(boardId)/columns/\(columnId)",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateColumn")
        )
    }
}
