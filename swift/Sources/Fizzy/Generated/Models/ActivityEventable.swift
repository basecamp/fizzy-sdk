// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct ActivityEventable: Codable, Sendable {
    public let id: String
    public let url: String
    public var assignees: [User]?
    public var board: Board?
    public var body: RichTextBody?
    public var card: CardRef?
    public var closed: Bool?
    public var column: Column?
    public var commentsUrl: String?
    public var createdAt: String?
    public var creator: User?
    public var description: String?
    public var descriptionHtml: String?
    public var golden: Bool?
    public var hasAttachments: Bool?
    public var hasMoreAssignees: Bool?
    public var imageUrl: String?
    public var lastActiveAt: String?
    public var number: Int32?
    public var postponed: Bool?
    public var reactionsUrl: String?
    public var status: String?
    public var steps: [Step]?
    public var tags: [String]?
    public var title: String?
    public var updatedAt: String?

    public init(
        id: String,
        url: String,
        assignees: [User]? = nil,
        board: Board? = nil,
        body: RichTextBody? = nil,
        card: CardRef? = nil,
        closed: Bool? = nil,
        column: Column? = nil,
        commentsUrl: String? = nil,
        createdAt: String? = nil,
        creator: User? = nil,
        description: String? = nil,
        descriptionHtml: String? = nil,
        golden: Bool? = nil,
        hasAttachments: Bool? = nil,
        hasMoreAssignees: Bool? = nil,
        imageUrl: String? = nil,
        lastActiveAt: String? = nil,
        number: Int32? = nil,
        postponed: Bool? = nil,
        reactionsUrl: String? = nil,
        status: String? = nil,
        steps: [Step]? = nil,
        tags: [String]? = nil,
        title: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.url = url
        self.assignees = assignees
        self.board = board
        self.body = body
        self.card = card
        self.closed = closed
        self.column = column
        self.commentsUrl = commentsUrl
        self.createdAt = createdAt
        self.creator = creator
        self.description = description
        self.descriptionHtml = descriptionHtml
        self.golden = golden
        self.hasAttachments = hasAttachments
        self.hasMoreAssignees = hasMoreAssignees
        self.imageUrl = imageUrl
        self.lastActiveAt = lastActiveAt
        self.number = number
        self.postponed = postponed
        self.reactionsUrl = reactionsUrl
        self.status = status
        self.steps = steps
        self.tags = tags
        self.title = title
        self.updatedAt = updatedAt
    }
}
