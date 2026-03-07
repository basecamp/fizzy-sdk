/**
 * Reactions service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export type Reaction = components["schemas"]["Reaction"];

export interface CreateCommentReactionRequest {
  /** Text content */
  content: string;
}

export interface CreateCardReactionRequest {
  /** Text content */
  content: string;
}

export class ReactionsService extends BaseService {

  /**
   * ListCommentReactions
   */
  async listForComment(cardNumber: number, commentId: string): Promise<ListResult<Reaction>> {
    return this.request(
      {
        service: "Comment reactions",
        operation: "ListCommentReactions",
        resourceType: "comment_reactions",
        isMutation: false,
      },
      () => this.client.GET("/cards/{cardNumber}/comments/{commentId}/reactions.json" as never, {
        params: { path: { cardNumber, commentId } },
      } as never),
    );
  }

  /**
   * CreateCommentReaction
   */
  async createForComment(cardNumber: number, commentId: string, body: CreateCommentReactionRequest): Promise<Reaction> {
    return this.request(
      {
        service: "Comment reaction",
        operation: "CreateCommentReaction",
        resourceType: "comment_reaction",
        isMutation: true,
      },
      () => this.client.POST("/cards/{cardNumber}/comments/{commentId}/reactions.json" as never, {
        params: { path: { cardNumber, commentId } },
        body: { content: body.content } as never,
      } as never),
    );
  }

  /**
   * DeleteCommentReaction
   */
  async deleteForComment(cardNumber: number, commentId: string, reactionId: string): Promise<void> {
    return this.request(
      {
        service: "Comment reaction",
        operation: "DeleteCommentReaction",
        resourceType: "comment_reaction",
        isMutation: true,
      },
      () => this.client.DELETE("/cards/{cardNumber}/comments/{commentId}/reactions/{reactionId}" as never, {
        params: { path: { cardNumber, commentId, reactionId } },
      } as never),
    );
  }

  /**
   * ListCardReactions
   */
  async listForCard(cardNumber: number): Promise<ListResult<Reaction>> {
    return this.request(
      {
        service: "Card reactions",
        operation: "ListCardReactions",
        resourceType: "card_reactions",
        isMutation: false,
      },
      () => this.client.GET("/cards/{cardNumber}/reactions.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * CreateCardReaction
   */
  async createForCard(cardNumber: number, body: CreateCardReactionRequest): Promise<Reaction> {
    return this.request(
      {
        service: "Card reaction",
        operation: "CreateCardReaction",
        resourceType: "card_reaction",
        isMutation: true,
      },
      () => this.client.POST("/cards/{cardNumber}/reactions.json" as never, {
        params: { path: { cardNumber } },
        body: { content: body.content } as never,
      } as never),
    );
  }

  /**
   * DeleteCardReaction
   */
  async deleteForCard(cardNumber: number, reactionId: string): Promise<void> {
    return this.request(
      {
        service: "Card reaction",
        operation: "DeleteCardReaction",
        resourceType: "card_reaction",
        isMutation: true,
      },
      () => this.client.DELETE("/cards/{cardNumber}/reactions/{reactionId}" as never, {
        params: { path: { cardNumber, reactionId } },
      } as never),
    );
  }
}
