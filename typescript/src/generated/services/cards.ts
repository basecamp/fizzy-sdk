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
  indexedBy?: string;
  sortedBy?: string;
  assignmentStatus?: string;
  creation?: string;
  closure?: string;
  terms?: string[];
}

export interface CreateCardRequest {
  /** Title */
  title: string;
  boardId?: string;
  columnId?: string;
  /** Rich text description (HTML) */
  description?: string;
  /** User IDs to assign to */
  assigneeIds?: string[];
  tagNames?: string[];
  image?: string;
  createdAt?: string;
  lastActiveAt?: string;
}

export interface UpdateCardRequest {
  /** Title */
  title?: string;
  /** Rich text description (HTML) */
  description?: string;
  columnId?: string;
  image?: string;
  createdAt?: string;
}

export interface AssignCardRequest {
  assigneeId: string;
}

export interface MoveCardRequest {
  boardId: string;
  columnId?: string;
}

export interface TagCardRequest {
  tagTitle: string;
}

export interface TriageCardRequest {
  columnId?: string;
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
        params: { query: { "board_ids[]": options?.boardIds, "tag_ids[]": options?.tagIds, "assignee_ids[]": options?.assigneeIds, "creator_ids[]": options?.creatorIds, "closer_ids[]": options?.closerIds, "card_ids[]": options?.cardIds, "indexed_by": options?.indexedBy, "sorted_by": options?.sortedBy, "assignment_status": options?.assignmentStatus, "creation": options?.creation, "closure": options?.closure, "terms[]": options?.terms } },
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
        body: { title: body.title, board_id: body.boardId, column_id: body.columnId, description: body.description, assignee_ids: body.assigneeIds, tag_names: body.tagNames, image: body.image, created_at: body.createdAt, last_active_at: body.lastActiveAt } as never,
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
   * UpdateCard
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
        body: { title: body?.title, description: body?.description, column_id: body?.columnId, image: body?.image, created_at: body?.createdAt } as never,
      } as never),
    );
  }

  /**
   * AssignCard
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
        body: { board_id: body.boardId, column_id: body.columnId } as never,
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
   * PostponeCard
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
   * UnpinCard
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
   * SelfAssignCard
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
   * TagCard
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
   * UnTriageCard
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
   * TriageCard
   */
  async triage(cardNumber: number, body?: TriageCardRequest): Promise<void> {
    return this.request(
      {
        service: "Card",
        operation: "TriageCard",
        resourceType: "card",
        isMutation: true,
      },
      () => this.client.POST("/cards/{cardNumber}/triage.json" as never, {
        params: { path: { cardNumber } },
        body: { column_id: body?.columnId } as never,
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
