// @generated from OpenAPI spec — do not edit directly
import Foundation

extension FizzyClient {
    private var account: AccountClient {
        service("__account") { AccountClient(client: self) }
    }

    public var boards: BoardsService { account.boards }
    public var cards: CardsService { account.cards }
    public var columns: ColumnsService { account.columns }
    public var comments: CommentsService { account.comments }
    public var devices: DevicesService { account.devices }
    public var identity: IdentityService { account.identity }
    public var notifications: NotificationsService { account.notifications }
    public var pins: PinsService { account.pins }
    public var reactions: ReactionsService { account.reactions }
    public var sessions: SessionsService { account.sessions }
    public var steps: StepsService { account.steps }
    public var tags: TagsService { account.tags }
    public var uploads: UploadsService { account.uploads }
    public var users: UsersService { account.users }
    public var webhooks: WebhooksService { account.webhooks }
}
