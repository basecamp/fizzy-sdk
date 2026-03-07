// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct ListBoardOptions: Sendable {
    public var maxItems: Int?

    public init(maxItems: Int? = nil) {
        self.maxItems = maxItems
    }
}


public final class BoardsService: BaseService, @unchecked Sendable {
    public func create(accountId: String, req: CreateBoardRequest) async throws -> Board {
        return try await request(
            OperationInfo(service: "Boards", operation: "CreateBoard", resourceType: "board", isMutation: true),
            method: "POST",
            path: "/\(accountId)/boards.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "CreateBoard")
        )
    }

    public func delete(accountId: String, boardId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Boards", operation: "DeleteBoard", resourceType: "board", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/boards/\(boardId)",
            retryConfig: Metadata.retryConfig(for: "DeleteBoard")
        )
    }

    public func get(accountId: String, boardId: String) async throws -> Board {
        return try await request(
            OperationInfo(service: "Boards", operation: "GetBoard", resourceType: "board", isMutation: false),
            method: "GET",
            path: "/\(accountId)/boards/\(boardId)",
            retryConfig: Metadata.retryConfig(for: "GetBoard")
        )
    }

    public func list(accountId: String, options: ListBoardOptions? = nil) async throws -> ListResult<Board> {
        return try await requestPaginated(
            OperationInfo(service: "Boards", operation: "ListBoards", resourceType: "board", isMutation: false),
            path: "/\(accountId)/boards.json",
            paginationOpts: options.flatMap { PaginationOptions(maxItems: $0.maxItems) },
            retryConfig: Metadata.retryConfig(for: "ListBoards")
        )
    }

    public func update(accountId: String, boardId: String, req: UpdateBoardRequest) async throws -> Board {
        return try await request(
            OperationInfo(service: "Boards", operation: "UpdateBoard", resourceType: "board", isMutation: true),
            method: "PATCH",
            path: "/\(accountId)/boards/\(boardId)",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateBoard")
        )
    }
}
