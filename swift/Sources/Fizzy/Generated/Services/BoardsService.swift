// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct ListBoardAccessesBoardOptions: Sendable {
    public var page: Int32?

    public init(page: Int32? = nil) {
        self.page = page
    }
}

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

    public func listBoardAccesses(accountId: String, boardId: String, options: ListBoardAccessesBoardOptions? = nil) async throws -> BoardAccesses {
        var queryItems: [URLQueryItem] = []
        if let page = options?.page {
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
        }
        return try await request(
            OperationInfo(service: "Boards", operation: "ListBoardAccesses", resourceType: "board_access", isMutation: false),
            method: "GET",
            path: "/\(accountId)/boards/\(boardId)/accesses.json" + queryString(queryItems),
            retryConfig: Metadata.retryConfig(for: "ListBoardAccesses")
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

    public func publishBoard(accountId: String, boardId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Boards", operation: "PublishBoard", resourceType: "resource", isMutation: true),
            method: "POST",
            path: "/\(accountId)/boards/\(boardId)/publication.json",
            retryConfig: Metadata.retryConfig(for: "PublishBoard")
        )
    }

    public func unpublishBoard(accountId: String, boardId: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Boards", operation: "UnpublishBoard", resourceType: "resource", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/boards/\(boardId)/publication.json",
            retryConfig: Metadata.retryConfig(for: "UnpublishBoard")
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
