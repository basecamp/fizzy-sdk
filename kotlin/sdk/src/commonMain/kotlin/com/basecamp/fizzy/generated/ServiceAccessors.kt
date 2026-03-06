package com.basecamp.fizzy.generated

import com.basecamp.fizzy.AccountClient
import com.basecamp.fizzy.generated.services.*

/**
 * Generated service accessor extensions for [AccountClient].
 *
 * These properties provide lazy, cached access to all Fizzy API services.
 *
 * @generated from OpenAPI spec -- do not edit directly
 */

/** Boards operations. */
val AccountClient.boards: BoardsService
    get() = service("Boards") { BoardsService(this) }

/** Cards operations. */
val AccountClient.cards: CardsService
    get() = service("Cards") { CardsService(this) }

/** Columns operations. */
val AccountClient.columns: ColumnsService
    get() = service("Columns") { ColumnsService(this) }

/** Comments operations. */
val AccountClient.comments: CommentsService
    get() = service("Comments") { CommentsService(this) }

/** Devices operations. */
val AccountClient.devices: DevicesService
    get() = service("Devices") { DevicesService(this) }

/** Identity operations. */
val AccountClient.identity: IdentityService
    get() = service("Identity") { IdentityService(this) }

/** Notifications operations. */
val AccountClient.notifications: NotificationsService
    get() = service("Notifications") { NotificationsService(this) }

/** Pins operations. */
val AccountClient.pins: PinsService
    get() = service("Pins") { PinsService(this) }

/** Reactions operations. */
val AccountClient.reactions: ReactionsService
    get() = service("Reactions") { ReactionsService(this) }

/** Sessions operations. */
val AccountClient.sessions: SessionsService
    get() = service("Sessions") { SessionsService(this) }

/** Steps operations. */
val AccountClient.steps: StepsService
    get() = service("Steps") { StepsService(this) }

/** Tags operations. */
val AccountClient.tags: TagsService
    get() = service("Tags") { TagsService(this) }

/** Uploads operations. */
val AccountClient.uploads: UploadsService
    get() = service("Uploads") { UploadsService(this) }

/** Users operations. */
val AccountClient.users: UsersService
    get() = service("Users") { UsersService(this) }

/** Webhooks operations. */
val AccountClient.webhooks: WebhooksService
    get() = service("Webhooks") { WebhooksService(this) }

