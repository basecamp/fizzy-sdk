// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct ListActivitiesCardOptions: Sendable {
    public var creatorIds: [String]?
    public var boardIds: [String]?
    public var maxItems: Int?

    public init(creatorIds: [String]? = nil, boardIds: [String]? = nil, maxItems: Int? = nil) {
        self.creatorIds = creatorIds
        self.boardIds = boardIds
        self.maxItems = maxItems
    }
}

public struct ListCardOptions: Sendable {
    public var boardIds: [String]?
    public var tagIds: [String]?
    public var assigneeIds: [String]?
    public var creatorIds: [String]?
    public var closerIds: [String]?
    public var cardIds: [String]?
    public var indexedBy: String?
    public var sortedBy: String?
    public var assignmentStatus: String?
    public var creation: String?
    public var closure: String?
    public var terms: [String]?
    public var maxItems: Int?

    public init(
        boardIds: [String]? = nil,
        tagIds: [String]? = nil,
        assigneeIds: [String]? = nil,
        creatorIds: [String]? = nil,
        closerIds: [String]? = nil,
        cardIds: [String]? = nil,
        indexedBy: String? = nil,
        sortedBy: String? = nil,
        assignmentStatus: String? = nil,
        creation: String? = nil,
        closure: String? = nil,
        terms: [String]? = nil,
        maxItems: Int? = nil
    ) {
        self.boardIds = boardIds
        self.tagIds = tagIds
        self.assigneeIds = assigneeIds
        self.creatorIds = creatorIds
        self.closerIds = closerIds
        self.cardIds = cardIds
        self.indexedBy = indexedBy
        self.sortedBy = sortedBy
        self.assignmentStatus = assignmentStatus
        self.creation = creation
        self.closure = closure
        self.terms = terms
        self.maxItems = maxItems
    }
}

public struct ListClosedCardsCardOptions: Sendable {
    public var maxItems: Int?

    public init(maxItems: Int? = nil) {
        self.maxItems = maxItems
    }
}

public struct ListColumnCardsCardOptions: Sendable {
    public var maxItems: Int?

    public init(maxItems: Int? = nil) {
        self.maxItems = maxItems
    }
}

public struct ListPostponedCardsCardOptions: Sendable {
    public var maxItems: Int?

    public init(maxItems: Int? = nil) {
        self.maxItems = maxItems
    }
}

public struct ListStreamCardsCardOptions: Sendable {
    public var maxItems: Int?

    public init(maxItems: Int? = nil) {
        self.maxItems = maxItems
    }
}

public struct SearchCardOptions: Sendable {
    public var maxItems: Int?

    public init(maxItems: Int? = nil) {
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

    public func listActivities(accountId: String, options: ListActivitiesCardOptions? = nil) async throws -> ListResult<Activity> {
        var queryItems: [URLQueryItem] = []
        if let creatorIds = options?.creatorIds {
            for value in creatorIds {
                queryItems.append(URLQueryItem(name: "creator_ids[]", value: String(value)))
            }
        }
        if let boardIds = options?.boardIds {
            for value in boardIds {
                queryItems.append(URLQueryItem(name: "board_ids[]", value: String(value)))
            }
        }
        return try await requestPaginated(
            OperationInfo(service: "Cards", operation: "ListActivities", resourceType: "activity", isMutation: false),
            path: "/\(accountId)/activities.json",
            queryItems: queryItems.isEmpty ? nil : queryItems,
            paginationOpts: options.flatMap { PaginationOptions(maxItems: $0.maxItems) },
            retryConfig: Metadata.retryConfig(for: "ListActivities")
        )
    }

    public func list(accountId: String, options: ListCardOptions? = nil) async throws -> ListResult<Card> {
        var queryItems: [URLQueryItem] = []
        if let boardIds = options?.boardIds {
            for value in boardIds {
                queryItems.append(URLQueryItem(name: "board_ids[]", value: String(value)))
            }
        }
        if let tagIds = options?.tagIds {
            for value in tagIds {
                queryItems.append(URLQueryItem(name: "tag_ids[]", value: String(value)))
            }
        }
        if let assigneeIds = options?.assigneeIds {
            for value in assigneeIds {
                queryItems.append(URLQueryItem(name: "assignee_ids[]", value: String(value)))
            }
        }
        if let creatorIds = options?.creatorIds {
            for value in creatorIds {
                queryItems.append(URLQueryItem(name: "creator_ids[]", value: String(value)))
            }
        }
        if let closerIds = options?.closerIds {
            for value in closerIds {
                queryItems.append(URLQueryItem(name: "closer_ids[]", value: String(value)))
            }
        }
        if let cardIds = options?.cardIds {
            for value in cardIds {
                queryItems.append(URLQueryItem(name: "card_ids[]", value: String(value)))
            }
        }
        if let indexedBy = options?.indexedBy {
            queryItems.append(URLQueryItem(name: "indexed_by", value: indexedBy))
        }
        if let sortedBy = options?.sortedBy {
            queryItems.append(URLQueryItem(name: "sorted_by", value: sortedBy))
        }
        if let assignmentStatus = options?.assignmentStatus {
            queryItems.append(URLQueryItem(name: "assignment_status", value: assignmentStatus))
        }
        if let creation = options?.creation {
            queryItems.append(URLQueryItem(name: "creation", value: creation))
        }
        if let closure = options?.closure {
            queryItems.append(URLQueryItem(name: "closure", value: closure))
        }
        if let terms = options?.terms {
            for value in terms {
                queryItems.append(URLQueryItem(name: "terms[]", value: String(value)))
            }
        }
        return try await requestPaginated(
            OperationInfo(service: "Cards", operation: "ListCards", resourceType: "card", isMutation: false),
            path: "/\(accountId)/cards.json",
            queryItems: queryItems.isEmpty ? nil : queryItems,
            paginationOpts: options.flatMap { PaginationOptions(maxItems: $0.maxItems) },
            retryConfig: Metadata.retryConfig(for: "ListCards")
        )
    }

    public func listClosedCards(accountId: String, boardId: String, options: ListClosedCardsCardOptions? = nil) async throws -> ListResult<Card> {
        return try await requestPaginated(
            OperationInfo(service: "Cards", operation: "ListClosedCards", resourceType: "closed_card", isMutation: false),
            path: "/\(accountId)/boards/\(boardId)/columns/closed.json",
            paginationOpts: options.flatMap { PaginationOptions(maxItems: $0.maxItems) },
            retryConfig: Metadata.retryConfig(for: "ListClosedCards")
        )
    }

    public func listColumnCards(accountId: String, boardId: String, columnId: String, options: ListColumnCardsCardOptions? = nil) async throws -> ListResult<Card> {
        return try await requestPaginated(
            OperationInfo(service: "Cards", operation: "ListColumnCards", resourceType: "column_card", isMutation: false),
            path: "/\(accountId)/boards/\(boardId)/columns/\(columnId)/cards.json",
            paginationOpts: options.flatMap { PaginationOptions(maxItems: $0.maxItems) },
            retryConfig: Metadata.retryConfig(for: "ListColumnCards")
        )
    }

    public func listPostponedCards(accountId: String, boardId: String, options: ListPostponedCardsCardOptions? = nil) async throws -> ListResult<Card> {
        return try await requestPaginated(
            OperationInfo(service: "Cards", operation: "ListPostponedCards", resourceType: "postponed_card", isMutation: false),
            path: "/\(accountId)/boards/\(boardId)/columns/not_now.json",
            paginationOpts: options.flatMap { PaginationOptions(maxItems: $0.maxItems) },
            retryConfig: Metadata.retryConfig(for: "ListPostponedCards")
        )
    }

    public func listStreamCards(accountId: String, boardId: String, options: ListStreamCardsCardOptions? = nil) async throws -> ListResult<Card> {
        return try await requestPaginated(
            OperationInfo(service: "Cards", operation: "ListStreamCards", resourceType: "stream_card", isMutation: false),
            path: "/\(accountId)/boards/\(boardId)/columns/stream.json",
            paginationOpts: options.flatMap { PaginationOptions(maxItems: $0.maxItems) },
            retryConfig: Metadata.retryConfig(for: "ListStreamCards")
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

    public func publishCard(accountId: String, cardNumber: Int) async throws {
        try await requestVoid(
            OperationInfo(service: "Cards", operation: "PublishCard", resourceType: "resource", isMutation: true),
            method: "POST",
            path: "/\(accountId)/cards/\(cardNumber)/publish.json",
            retryConfig: Metadata.retryConfig(for: "PublishCard")
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

    public func search(accountId: String, q: String, options: SearchCardOptions? = nil) async throws -> ListResult<Card> {
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "q", value: q))
        return try await requestPaginated(
            OperationInfo(service: "Cards", operation: "SearchCards", resourceType: "card", isMutation: false),
            path: "/\(accountId)/search.json",
            queryItems: queryItems.isEmpty ? nil : queryItems,
            paginationOpts: options.flatMap { PaginationOptions(maxItems: $0.maxItems) },
            retryConfig: Metadata.retryConfig(for: "SearchCards")
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
