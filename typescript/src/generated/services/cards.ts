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

export interface CreateCardRequest {
  /** Title */
  title: string;
  /** Body content (Markdown or HTML) */
  body?: string;
  /** Column ID to place the card in */
  columnId?: number;
  /** User IDs to assign to */
  assigneeIds?: number[];
}

export interface UpdateCardRequest {
  /** Title */
  title?: string;
  /** Body content (Markdown or HTML) */
  body?: string;
}

export interface MoveCardRequest {
  /** Target column ID */
  columnId: number;
  /** Position within the column (1-based) */
  position?: number;
}

export interface AssignCardRequest {
  /** User IDs to assign */
  assigneeIds: number[];
}

export interface TagCardRequest {
  /** Tag IDs to apply */
  tagIds: number[];
}

export class CardsService extends BaseService {

  /**
   * List all cards for a board.
   */
  async list(boardId: number, options?: PaginationOptions): Promise<ListResult<Card>> {
    return this.requestPaginated(
      {
        service: "Cards",
        operation: "List",
        resourceType: "card",
        isMutation: false,
        boardId,
      },
      () => this.client.GET("/boards/{boardId}/cards.json" as never, {
        params: { path: { boardId } },
      } as never),
      options,
    );
  }

  /**
   * Create a new card on a board.
   */
  async create(boardId: number, body: CreateCardRequest): Promise<Card> {
    return this.request(
      {
        service: "Cards",
        operation: "Create",
        resourceType: "card",
        isMutation: true,
        boardId,
      },
      () => this.client.POST("/boards/{boardId}/cards.json" as never, {
        params: { path: { boardId } },
        body: { title: body.title, body: body.body, column_id: body.columnId, assignee_ids: body.assigneeIds } as never,
      } as never),
    );
  }

  /**
   * Get a single card by number.
   */
  async get(cardNumber: number): Promise<Card> {
    return this.request(
      {
        service: "Cards",
        operation: "Get",
        resourceType: "card",
        isMutation: false,
        resourceId: cardNumber,
      },
      () => this.client.GET("/cards/{cardNumber}.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Update a card.
   */
  async update(cardNumber: number, body: UpdateCardRequest): Promise<Card> {
    return this.request(
      {
        service: "Cards",
        operation: "Update",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.PATCH("/cards/{cardNumber}" as never, {
        params: { path: { cardNumber } },
        body: { title: body.title, body: body.body } as never,
      } as never),
    );
  }

  /**
   * Delete a card. Deleted cards cannot be recovered.
   */
  async delete(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Cards",
        operation: "Delete",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.DELETE("/cards/{cardNumber}.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Close a card.
   */
  async close(cardNumber: number): Promise<Card> {
    return this.request(
      {
        service: "Cards",
        operation: "Close",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.POST("/cards/{cardNumber}/closure.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Reopen a closed card.
   */
  async reopen(cardNumber: number): Promise<Card> {
    return this.request(
      {
        service: "Cards",
        operation: "Reopen",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.DELETE("/cards/{cardNumber}/closure.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Postpone a card.
   */
  async postpone(cardNumber: number): Promise<Card> {
    return this.request(
      {
        service: "Cards",
        operation: "Postpone",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.POST("/cards/{cardNumber}/not_now.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Triage a card.
   */
  async triage(cardNumber: number): Promise<Card> {
    return this.request(
      {
        service: "Cards",
        operation: "Triage",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.POST("/cards/{cardNumber}/triage.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Remove a card from triage.
   */
  async untriage(cardNumber: number): Promise<Card> {
    return this.request(
      {
        service: "Cards",
        operation: "UnTriageCard",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.DELETE("/cards/{cardNumber}/triage.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Mark a card as gold.
   */
  async gold(cardNumber: number): Promise<Card> {
    return this.request(
      {
        service: "Cards",
        operation: "Gold",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.POST("/cards/{cardNumber}/goldness.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Remove gold status from a card.
   */
  async ungold(cardNumber: number): Promise<Card> {
    return this.request(
      {
        service: "Cards",
        operation: "UngoldCard",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.DELETE("/cards/{cardNumber}/goldness.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Assign users to a card.
   */
  async assign(cardNumber: number, body: AssignCardRequest): Promise<Card> {
    return this.request(
      {
        service: "Cards",
        operation: "Assign",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.POST("/cards/{cardNumber}/assignments.json" as never, {
        params: { path: { cardNumber } },
        body: { assignee_ids: body.assigneeIds } as never,
      } as never),
    );
  }

  /**
   * Assign yourself to a card.
   */
  async selfAssign(cardNumber: number): Promise<Card> {
    return this.request(
      {
        service: "Cards",
        operation: "SelfAssign",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.POST("/cards/{cardNumber}/self_assignment.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Apply tags to a card.
   */
  async tag(cardNumber: number, body: TagCardRequest): Promise<Card> {
    return this.request(
      {
        service: "Cards",
        operation: "Tag",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.POST("/cards/{cardNumber}/taggings.json" as never, {
        params: { path: { cardNumber } },
        body: { tag_ids: body.tagIds } as never,
      } as never),
    );
  }

  /**
   * Watch a card for notifications.
   */
  async watch(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Cards",
        operation: "Watch",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.POST("/cards/{cardNumber}/watch.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Stop watching a card.
   */
  async unwatch(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Cards",
        operation: "UnwatchCard",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.DELETE("/cards/{cardNumber}/watch.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Pin a card.
   */
  async pin(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Cards",
        operation: "Pin",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.POST("/cards/{cardNumber}/pin.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Unpin a card.
   */
  async unpin(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Cards",
        operation: "UnpinCard",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.DELETE("/cards/{cardNumber}/pin.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * Move a card to a different column.
   */
  async move(cardNumber: number, body: MoveCardRequest): Promise<Card> {
    return this.request(
      {
        service: "Cards",
        operation: "Move",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.PATCH("/cards/{cardNumber}/board.json" as never, {
        params: { path: { cardNumber } },
        body: { column_id: body.columnId, position: body.position } as never,
      } as never),
    );
  }

  /**
   * Delete a card's image.
   */
  async deleteImage(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Cards",
        operation: "DeleteImage",
        resourceType: "card",
        isMutation: true,
        resourceId: cardNumber,
      },
      () => this.client.DELETE("/cards/{cardNumber}/image.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }
}
