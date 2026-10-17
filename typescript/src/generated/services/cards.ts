/**
 * Cards service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export type Card = components["schemas"]["Card"];

export interface ListActivitiesActivitiesOptions extends PaginationOptions {
  creatorIds?: string[];
  boardIds?: string[];
}

export interface ListCardsOptions extends PaginationOptions {
  boardIds?: string[];
  tagIds?: string[];
  assigneeIds?: string[];
  creatorIds?: string[];
  closerIds?: string[];
  cardIds?: string[];
  columnIds?: string[];
  /** Which cards to list: "all" (default, open cards), "maybe" (awaiting triage), "closed", "not_now", "stalled", "postponing_soon" or "golden". Any other value lists the same cards as "all". */
  indexedBy?: string;
  /** "latest" (default, most recently active first), "newest" or "oldest" (by creation). Any other value sorts as "latest". */
  sortedBy?: string;
  /** "unassigned" lists only cards with no assignee; any other value is ignored. */
  assignmentStatus?: string;
  /** Created within: "today", "yesterday", "thisweek", "lastweek", "thismonth", "lastmonth", "thisyear" or "lastyear" (TimeWindowParser); any other value is ignored. */
  creation?: string;
  /** Closed within: "today", "yesterday", "thisweek", "lastweek", "thismonth", "lastmonth", "thisyear" or "lastyear" (TimeWindowParser); any other value is ignored. */
  closure?: string;
  terms?: string[];
}

export interface CreateCardRequest {
  /** Title */
  title: string;
  /** The board to create the card on. Required: CardsController finds it unconditionally. */
  boardId: string;
  /** Rich text description (HTML) */
  description?: string;
  /** The signed blob id of an image uploaded with CreateDirectUpload. A caller that can't make the upload has no value to send here. */
  image?: string;
  createdAt?: string;
  lastActiveAt?: string;
}

export interface UpdateCardRequest {
  /** Title */
  title?: string;
  /** Rich text description (HTML) */
  description?: string;
  /** The signed blob id of an image uploaded with CreateDirectUpload. A caller that can't make the upload has no value to send here. */
  image?: string;
  createdAt?: string;
}

export interface AssignCardRequest {
  assigneeId: string;
}

export interface MoveCardRequest {
  /** The destination board. Cards::BoardsController reads no column. */
  boardId: string;
}

export interface TagCardRequest {
  /** The tag's title; surrounding whitespace and a leading "#" are stripped. */
  tagTitle: string;
}

export interface TriageCardRequest {
  /** A column on the card's board. Required: the controller finds it unconditionally. */
  columnId: string;
}

export interface SearchCardsSearchcardsOptions extends PaginationOptions {
  q: string;
}

export class CardsService extends BaseService {

  /**
   * ListActivities
   */
  async listActivities(options?: ListActivitiesActivitiesOptions): Promise<ListResult<components["schemas"]["Activity"]>> {
    return this.requestPaginated(
      {
        service: "Activities",
        operation: "ListActivities",
        resourceType: "activities",
        isMutation: false,
      },
      () => this.client.GET("/activities.json" as never, {
        params: { query: { "creator_ids[]": options?.creatorIds, "board_ids[]": options?.boardIds } },
      } as never),
      options,
    );
  }

  /**
   * ListClosedCards
   */
  async listClosedCards(boardId: string, options?: PaginationOptions): Promise<ListResult<Card>> {
    return this.requestPaginated(
      {
        service: "Closed cards",
        operation: "ListClosedCards",
        resourceType: "closed_cards",
        isMutation: false,
      },
      () => this.client.GET("/boards/{boardId}/columns/closed.json" as never, {
        params: { path: { boardId } },
      } as never),
      options,
    );
  }

  /**
   * ListPostponedCards
   */
  async listPostponedCards(boardId: string, options?: PaginationOptions): Promise<ListResult<Card>> {
    return this.requestPaginated(
      {
        service: "Postponed cards",
        operation: "ListPostponedCards",
        resourceType: "postponed_cards",
        isMutation: false,
      },
      () => this.client.GET("/boards/{boardId}/columns/not_now.json" as never, {
        params: { path: { boardId } },
      } as never),
      options,
    );
  }

  /**
   * ListStreamCards
   */
  async listStreamCards(boardId: string, options?: PaginationOptions): Promise<ListResult<Card>> {
    return this.requestPaginated(
      {
        service: "Stream cards",
        operation: "ListStreamCards",
        resourceType: "stream_cards",
        isMutation: false,
      },
      () => this.client.GET("/boards/{boardId}/columns/stream.json" as never, {
        params: { path: { boardId } },
      } as never),
      options,
    );
  }

  /**
   * ListColumnCards
   */
  async listColumnCards(boardId: string, columnId: string, options?: PaginationOptions): Promise<ListResult<Card>> {
    return this.requestPaginated(
      {
        service: "Column cards",
        operation: "ListColumnCards",
        resourceType: "column_cards",
        isMutation: false,
      },
      () => this.client.GET("/boards/{boardId}/columns/{columnId}/cards.json" as never, {
        params: { path: { boardId, columnId } },
      } as never),
      options,
    );
  }

  /**
   * ListCards
   */
  async list(options?: ListCardsOptions): Promise<ListResult<Card>> {
    return this.requestPaginated(
      {
        service: "Cards",
        operation: "ListCards",
        resourceType: "cards",
        isMutation: false,
      },
      () => this.client.GET("/cards.json" as never, {
        params: { query: { "board_ids[]": options?.boardIds, "tag_ids[]": options?.tagIds, "assignee_ids[]": options?.assigneeIds, "creator_ids[]": options?.creatorIds, "closer_ids[]": options?.closerIds, "card_ids[]": options?.cardIds, "column_ids[]": options?.columnIds, "indexed_by": options?.indexedBy, "sorted_by": options?.sortedBy, "assignment_status": options?.assignmentStatus, "creation": options?.creation, "closure": options?.closure, "terms[]": options?.terms } },
      } as never),
      options,
    );
  }

  /**
   * CreateCard
   */
  async create(body: CreateCardRequest): Promise<Card> {
    return this.request(
      {
        service: "Card",
        operation: "CreateCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.POST("/cards.json" as never, {
        body: { title: body.title, board_id: body.boardId, description: body.description, image: body.image, created_at: body.createdAt, last_active_at: body.lastActiveAt } as never,
      } as never),
    );
  }

  /**
   * DeleteCard
   */
  async delete(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Card",
        operation: "DeleteCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.DELETE("/cards/{cardNumber}" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * GetCard
   */
  async get(cardNumber: number): Promise<Card> {
    return this.request(
      {
        service: "Card",
        operation: "GetCard",
        resourceType: "card",
        isMutation: false,
      },
      () => this.client.GET("/cards/{cardNumber}" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Updates a card. Send at least one of title, description, image or created_at: the controller expects a `card` object, so an empty body is a 400. Moving a card between columns is TriageCard, and between boards MoveCard.
   */
  async update(cardNumber: number, body?: UpdateCardRequest): Promise<Card> {
    return this.request(
      {
        service: "Card",
        operation: "UpdateCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.PATCH("/cards/{cardNumber}" as never, {
        params: { path: { cardNumber } },
        body: { title: body?.title, description: body?.description, image: body?.image, created_at: body?.createdAt } as never,
      } as never),
    );
  }

  /**
   * Assigns the user to the card, or unassigns them if they are already assigned. This is a toggle: calling it again undoes it, and both outcomes return 204, so a retry or a repeat reverses the first call. Check the card first when the outcome matters.
   */
  async assign(cardNumber: number, body: AssignCardRequest): Promise<void> {
    return this.request(
      {
        service: "Card",
        operation: "AssignCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.POST("/cards/{cardNumber}/assignments.json" as never, {
        params: { path: { cardNumber } },
        body: { assignee_id: body.assigneeId } as never,
      } as never),
    );
  }

  /**
   * MoveCard
   */
  async move(cardNumber: number, body: MoveCardRequest): Promise<Card> {
    return this.request(
      {
        service: "Card",
        operation: "MoveCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.PATCH("/cards/{cardNumber}/board.json" as never, {
        params: { path: { cardNumber } },
        body: { board_id: body.boardId } as never,
      } as never),
    );
  }

  /**
   * ReopenCard
   */
  async reopen(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Card",
        operation: "ReopenCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.DELETE("/cards/{cardNumber}/closure.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * CloseCard
   */
  async close(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Card",
        operation: "CloseCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.POST("/cards/{cardNumber}/closure.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * UngoldCard
   */
  async ungold(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Card",
        operation: "UngoldCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.DELETE("/cards/{cardNumber}/goldness.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * GoldCard
   */
  async gold(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Card",
        operation: "GoldCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.POST("/cards/{cardNumber}/goldness.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * DeleteCardImage
   */
  async deleteImage(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Card image",
        operation: "DeleteCardImage",
        resourceType: "card_image",
        isMutation: true,
      },
      () => this.client.DELETE("/cards/{cardNumber}/image.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Moves the card to Not Now. Each call records an event, which notifies webhooks and adds a system comment to the card, even when the card's state doesn't change, so it is not safe to retry.
   */
  async postpone(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Card",
        operation: "PostponeCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.POST("/cards/{cardNumber}/not_now.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Unpins the card for the caller. Unpinning a card the caller hasn't pinned currently fails with a 500 (Card::Pinnable#unpin_by destroys a pin it didn't find), so a retry after a success fails: not idempotent.
   */
  async unpin(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Card",
        operation: "UnpinCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.DELETE("/cards/{cardNumber}/pin.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * PinCard
   */
  async pin(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Card",
        operation: "PinCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.POST("/cards/{cardNumber}/pin.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * PublishCard
   */
  async publishCard(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Publishcard",
        operation: "PublishCard",
        resourceType: "publishcard",
        isMutation: true,
      },
      () => this.client.POST("/cards/{cardNumber}/publish.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Assigns the caller to the card, or unassigns them if they are already assigned. This is a toggle: calling it again undoes it, and both outcomes return 204, so a retry or a repeat reverses the first call. Check the card first when the outcome matters.
   */
  async selfAssign(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Card",
        operation: "SelfAssignCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.POST("/cards/{cardNumber}/self_assignment.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Tags the card, or untags it if it already has the tag. The tag is created when the account has none with that title. This is a toggle: calling it again undoes it, and both outcomes return 204, so a retry or a repeat reverses the first call. Check the card first when the outcome matters.
   */
  async tag(cardNumber: number, body: TagCardRequest): Promise<void> {
    return this.request(
      {
        service: "Card",
        operation: "TagCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.POST("/cards/{cardNumber}/taggings.json" as never, {
        params: { path: { cardNumber } },
        body: { tag_title: body.tagTitle } as never,
      } as never),
    );
  }

  /**
   * Sends the card back to triage (Maybe?). Each call records an event, which notifies webhooks and adds a system comment to the card, even when the card's state doesn't change, so it is not safe to retry.
   */
  async untriage(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Card",
        operation: "UnTriageCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.DELETE("/cards/{cardNumber}/triage.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Triages the card into a column of its board. Each call records an event, which notifies webhooks and adds a system comment to the card, even when the card's state doesn't change, so it is not safe to retry.
   */
  async triage(cardNumber: number, body: TriageCardRequest): Promise<void> {
    return this.request(
      {
        service: "Card",
        operation: "TriageCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.POST("/cards/{cardNumber}/triage.json" as never, {
        params: { path: { cardNumber } },
        body: { column_id: body.columnId } as never,
      } as never),
    );
  }

  /**
   * UnwatchCard
   */
  async unwatch(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Card",
        operation: "UnwatchCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.DELETE("/cards/{cardNumber}/watch.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * WatchCard
   */
  async watch(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Card",
        operation: "WatchCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.POST("/cards/{cardNumber}/watch.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * SearchCards
   */
  async searchCards(options?: SearchCardsSearchcardsOptions): Promise<ListResult<Card>> {
    return this.requestPaginated(
      {
        service: "Searchcards",
        operation: "SearchCards",
        resourceType: "searchcards",
        isMutation: false,
      },
      () => this.client.GET("/search.json" as never, {
        params: { query: { "q": options?.q } },
      } as never),
      options,
    );
  }
}
