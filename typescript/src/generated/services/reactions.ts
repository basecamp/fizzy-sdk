/**
 * Reactions service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export type Reaction = components["schemas"]["Reaction"];

export interface CreateReactionRequest {
  emoji: string;
}

export class ReactionsService extends BaseService {

  async listForCard(cardNumber: number): Promise<ListResult<Reaction>> {
    return this.requestPaginated(
      { service: "Reactions", operation: "ListForCard", resourceType: "reaction", isMutation: false },
      () => this.client.GET("/cards/{cardNumber}/reactions.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  async createForCard(cardNumber: number, body: CreateReactionRequest): Promise<Reaction> {
    return this.request(
      { service: "Reactions", operation: "CreateForCard", resourceType: "reaction", isMutation: true },
      () => this.client.POST("/cards/{cardNumber}/reactions.json" as never, {
        params: { path: { cardNumber } },
        body: { emoji: body.emoji } as never,
      } as never),
    );
  }

  async deleteForCard(cardNumber: number, reactionId: number): Promise<void> {
    return this.request(
      { service: "Reactions", operation: "DeleteForCard", resourceType: "reaction", isMutation: true, resourceId: reactionId },
      () => this.client.DELETE("/cards/{cardNumber}/reactions/{reactionId}.json" as never, {
        params: { path: { cardNumber, reactionId } },
      } as never),
    );
  }

  async listForComment(commentId: number): Promise<ListResult<Reaction>> {
    return this.requestPaginated(
      { service: "Reactions", operation: "ListForComment", resourceType: "reaction", isMutation: false },
      () => this.client.GET("/comments/{commentId}/reactions.json" as never, {
        params: { path: { commentId } },
      } as never),
    );
  }

  async createForComment(commentId: number, body: CreateReactionRequest): Promise<Reaction> {
    return this.request(
      { service: "Reactions", operation: "CreateForComment", resourceType: "reaction", isMutation: true },
      () => this.client.POST("/comments/{commentId}/reactions.json" as never, {
        params: { path: { commentId } },
        body: { emoji: body.emoji } as never,
      } as never),
    );
  }

  async deleteForComment(commentId: number, reactionId: number): Promise<void> {
    return this.request(
      { service: "Reactions", operation: "DeleteForComment", resourceType: "reaction", isMutation: true, resourceId: reactionId },
      () => this.client.DELETE("/comments/{commentId}/reactions/{reactionId}.json" as never, {
        params: { path: { commentId, reactionId } },
      } as never),
    );
  }
}
