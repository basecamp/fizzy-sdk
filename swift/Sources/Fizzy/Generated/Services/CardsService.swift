// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct ListCardOptions: Sendable {
    public var boardId: String?
    public var columnId: String?
    public var assigneeId: String?
    public var tag: String?
    public var status: String?
    public var q: String?
    public var maxItems: Int?

    public init(
        boardId: String? = nil,
        columnId: String? = nil,
        assigneeId: String? = nil,
        tag: String? = nil,
        status: String? = nil,
        q: String? = nil,
        maxItems: Int? = nil
    ) {
        self.boardId = boardId
        self.columnId = columnId
        self.assigneeId = assigneeId
        self.tag = tag
        self.status = status
        self.q = q
        self.maxItems = maxItems
    }
}


public final class CardsService: BaseService, @unchecked Sendable {
    public func assign(accountId: String, cardNumber: Int, req: AssignCardRequest) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "AssignCard", resourceType: "card", isMutation: true),
            method: "POST",
            path: "/\(accountId)/cards/\(cardNumber)/assignments.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "AssignCard")
        )
    }

    public func close(accountId: String, cardNumber: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "CloseCard", resourceType: "card", isMutation: true),
            method: "POST",
            path: "/\(accountId)/cards/\(cardNumber)/closure.json",
            retryConfig: Metadata.retryConfig(for: "CloseCard")
        )
    }

    public func create(accountId: String, req: CreateCardRequest) async throws -> Card {
        return try await request(
            OperationInfo(service: "Cards", operation: "CreateCard", resourceType: "card", isMutation: true),
            method: "POST",
            path: "/\(accountId)/cards.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "CreateCard")
        )
    }

    public func delete(accountId: String, cardNumber: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "DeleteCard", resourceType: "card", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/cards/\(cardNumber)",
            retryConfig: Metadata.retryConfig(for: "DeleteCard")
        )
    }

    public func deleteImage(accountId: String, cardNumber: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "DeleteCardImage", resourceType: "card_image", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/cards/\(cardNumber)/image.json",
            retryConfig: Metadata.retryConfig(for: "DeleteCardImage")
        )
    }

    public func get(accountId: String, cardNumber: Int) async throws -> Card {
        return try await request(
            OperationInfo(service: "Cards", operation: "GetCard", resourceType: "card", isMutation: false),
            method: "GET",
            path: "/\(accountId)/cards/\(cardNumber)",
            retryConfig: Metadata.retryConfig(for: "GetCard")
        )
    }

    public func gold(accountId: String, cardNumber: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "GoldCard", resourceType: "card", isMutation: true),
            method: "POST",
            path: "/\(accountId)/cards/\(cardNumber)/goldness.json",
            retryConfig: Metadata.retryConfig(for: "GoldCard")
        )
    }

    public func list(accountId: String, options: ListCardOptions? = nil) async throws -> ListResult<Card> {
        var queryItems: [URLQueryItem] = []
        if let boardId = options?.boardId {
            queryItems.append(URLQueryItem(name: "board_id", value: boardId))
        }
        if let columnId = options?.columnId {
            queryItems.append(URLQueryItem(name: "column_id", value: columnId))
        }
        if let assigneeId = options?.assigneeId {
            queryItems.append(URLQueryItem(name: "assignee_id", value: assigneeId))
        }
        if let tag = options?.tag {
            queryItems.append(URLQueryItem(name: "tag", value: tag))
        }
        if let status = options?.status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        if let q = options?.q {
            queryItems.append(URLQueryItem(name: "q", value: q))
        }
        return try await requestPaginated(
            OperationInfo(service: "Cards", operation: "ListCards", resourceType: "card", isMutation: false),
            path: "/\(accountId)/cards.json",
            queryItems: queryItems.isEmpty ? nil : queryItems,
            paginationOpts: options.flatMap { PaginationOptions(maxItems: $0.maxItems) },
            retryConfig: Metadata.retryConfig(for: "ListCards")
        )
    }

    public func move(accountId: String, cardNumber: Int, req: MoveCardRequest) async throws -> Card {
        return try await request(
            OperationInfo(service: "Cards", operation: "MoveCard", resourceType: "card", isMutation: true),
            method: "PATCH",
            path: "/\(accountId)/cards/\(cardNumber)/board.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "MoveCard")
        )
    }

    public func pin(accountId: String, cardNumber: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "PinCard", resourceType: "card", isMutation: true),
            method: "POST",
            path: "/\(accountId)/cards/\(cardNumber)/pin.json",
            retryConfig: Metadata.retryConfig(for: "PinCard")
        )
    }

    public func postpone(accountId: String, cardNumber: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "PostponeCard", resourceType: "card", isMutation: true),
            method: "POST",
            path: "/\(accountId)/cards/\(cardNumber)/not_now.json",
            retryConfig: Metadata.retryConfig(for: "PostponeCard")
        )
    }

    public func reopen(accountId: String, cardNumber: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "ReopenCard", resourceType: "card", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/cards/\(cardNumber)/closure.json",
            retryConfig: Metadata.retryConfig(for: "ReopenCard")
        )
    }

    public func selfAssign(accountId: String, cardNumber: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "SelfAssignCard", resourceType: "card", isMutation: true),
            method: "POST",
            path: "/\(accountId)/cards/\(cardNumber)/self_assignment.json",
            retryConfig: Metadata.retryConfig(for: "SelfAssignCard")
        )
    }

    public func tag(accountId: String, cardNumber: Int, req: TagCardRequest) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "TagCard", resourceType: "card", isMutation: true),
            method: "POST",
            path: "/\(accountId)/cards/\(cardNumber)/taggings.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "TagCard")
        )
    }

    public func triage(accountId: String, cardNumber: Int, req: TriageCardRequest) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "TriageCard", resourceType: "card", isMutation: true),
            method: "POST",
            path: "/\(accountId)/cards/\(cardNumber)/triage.json",
            body: req,
            retryConfig: Metadata.retryConfig(for: "TriageCard")
        )
    }

    public func untriage(accountId: String, cardNumber: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "UnTriageCard", resourceType: "resource", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/cards/\(cardNumber)/triage.json",
            retryConfig: Metadata.retryConfig(for: "UnTriageCard")
        )
    }

    public func ungold(accountId: String, cardNumber: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "UngoldCard", resourceType: "resource", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/cards/\(cardNumber)/goldness.json",
            retryConfig: Metadata.retryConfig(for: "UngoldCard")
        )
    }

    public func unpin(accountId: String, cardNumber: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "UnpinCard", resourceType: "card", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/cards/\(cardNumber)/pin.json",
            retryConfig: Metadata.retryConfig(for: "UnpinCard")
        )
    }

    public func unwatch(accountId: String, cardNumber: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "UnwatchCard", resourceType: "card", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/cards/\(cardNumber)/watch.json",
            retryConfig: Metadata.retryConfig(for: "UnwatchCard")
        )
    }

    public func update(accountId: String, cardNumber: Int, req: UpdateCardRequest) async throws -> Card {
        return try await request(
            OperationInfo(service: "Cards", operation: "UpdateCard", resourceType: "card", isMutation: true),
            method: "PATCH",
            path: "/\(accountId)/cards/\(cardNumber)",
            body: req,
            retryConfig: Metadata.retryConfig(for: "UpdateCard")
        )
    }

    public func watch(accountId: String, cardNumber: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "WatchCard", resourceType: "card", isMutation: true),
            method: "POST",
            path: "/\(accountId)/cards/\(cardNumber)/watch.json",
            retryConfig: Metadata.retryConfig(for: "WatchCard")
        )
    }
}
