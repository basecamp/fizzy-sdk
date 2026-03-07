// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Card: Codable, Sendable {
    public let closed: Bool
    public let createdAt: String
    public let golden: Bool
    public let hasAttachments: Bool
    public let id: String
    public let number: Int32
    public let postponed: Bool
    public let status: String
    public let title: String
    public let url: String
    public var assignees: [UserSummary]?
    public var board: BoardSummary?
    public var column: ColumnSummary?
    public var commentsUrl: String?
    public var creator: UserSummary?
    public var description: String?
    public var descriptionHtml: String?
    public var hasMoreAssignees: Bool?
    public var imageUrl: String?
    public var lastActiveAt: String?
    public var reactionsUrl: String?
    public var steps: [Step]?
    public var tags: [String]?

    public init(
        closed: Bool,
        createdAt: String,
        golden: Bool,
        hasAttachments: Bool,
        id: String,
        number: Int32,
        postponed: Bool,
        status: String,
        title: String,
        url: String,
        assignees: [UserSummary]? = nil,
        board: BoardSummary? = nil,
        column: ColumnSummary? = nil,
        commentsUrl: String? = nil,
        creator: UserSummary? = nil,
        description: String? = nil,
        descriptionHtml: String? = nil,
        hasMoreAssignees: Bool? = nil,
        imageUrl: String? = nil,
        lastActiveAt: String? = nil,
        reactionsUrl: String? = nil,
        steps: [Step]? = nil,
        tags: [String]? = nil
    ) {
        self.closed = closed
        self.createdAt = createdAt
        self.golden = golden
        self.hasAttachments = hasAttachments
        self.id = id
        self.number = number
        self.postponed = postponed
        self.status = status
        self.title = title
        self.url = url
        self.assignees = assignees
        self.board = board
        self.column = column
        self.commentsUrl = commentsUrl
        self.creator = creator
        self.description = description
        self.descriptionHtml = descriptionHtml
        self.hasMoreAssignees = hasMoreAssignees
        self.imageUrl = imageUrl
        self.lastActiveAt = lastActiveAt
        self.reactionsUrl = reactionsUrl
        self.steps = steps
        self.tags = tags
    }
}
