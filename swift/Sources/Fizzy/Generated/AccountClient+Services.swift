// @generated from OpenAPI spec — do not edit directly
import Foundation

extension AccountClient {
    public var boards: BoardsService { service("boards") { BoardsService(accountClient: self) } }
    public var cards: CardsService { service("cards") { CardsService(accountClient: self) } }
    public var columns: ColumnsService { service("columns") { ColumnsService(accountClient: self) } }
    public var comments: CommentsService { service("comments") { CommentsService(accountClient: self) } }
    public var devices: DevicesService { service("devices") { DevicesService(accountClient: self) } }
    public var identity: IdentityService { service("identity") { IdentityService(accountClient: self) } }
    public var notifications: NotificationsService { service("notifications") { NotificationsService(accountClient: self) } }
    public var pins: PinsService { service("pins") { PinsService(accountClient: self) } }
    public var reactions: ReactionsService { service("reactions") { ReactionsService(accountClient: self) } }
    public var sessions: SessionsService { service("sessions") { SessionsService(accountClient: self) } }
    public var steps: StepsService { service("steps") { StepsService(accountClient: self) } }
    public var tags: TagsService { service("tags") { TagsService(accountClient: self) } }
    public var uploads: UploadsService { service("uploads") { UploadsService(accountClient: self) } }
    public var users: UsersService { service("users") { UsersService(accountClient: self) } }
    public var webhooks: WebhooksService { service("webhooks") { WebhooksService(accountClient: self) } }
}
