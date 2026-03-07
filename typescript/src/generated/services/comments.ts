/**
 * Comments service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export type Comment = components["schemas"]["Comment"];

export interface CreateCommentRequest {
  /** Body content (Markdown or HTML) */
  body: string;
  createdAt?: string;
}

export interface UpdateCommentRequest {
  /** Body content (Markdown or HTML) */
  body: string;
}

export class CommentsService extends BaseService {

  /**
   * ListComments
   */
  async list(cardNumber: number, options?: PaginationOptions): Promise<ListResult<Comment>> {
    return this.requestPaginated(
      {
        service: "Comments",
        operation: "ListComments",
        resourceType: "comments",
        isMutation: false,
      },
      () => this.client.GET("/cards/{cardNumber}/comments.json" as never, {
        params: { path: { cardNumber } },
      } as never),
      options,
    );
  }

  /**
   * CreateComment
   */
  async create(cardNumber: number, body: CreateCommentRequest): Promise<Comment> {
    return this.request(
      {
        service: "Comment",
        operation: "CreateComment",
        resourceType: "comment",
        isMutation: true,
      },
      () => this.client.POST("/cards/{cardNumber}/comments.json" as never, {
        params: { path: { cardNumber } },
        body: { body: body.body, created_at: body.createdAt } as never,
      } as never),
    );
  }

  /**
   * DeleteComment
   */
  async delete(cardNumber: number, commentId: string): Promise<void> {
    return this.request(
      {
        service: "Comment",
        operation: "DeleteComment",
        resourceType: "comment",
        isMutation: true,
      },
      () => this.client.DELETE("/cards/{cardNumber}/comments/{commentId}" as never, {
        params: { path: { cardNumber, commentId } },
      } as never),
    );
  }

  /**
   * GetComment
   */
  async get(cardNumber: number, commentId: string): Promise<Comment> {
    return this.request(
      {
        service: "Comment",
        operation: "GetComment",
        resourceType: "comment",
        isMutation: false,
      },
      () => this.client.GET("/cards/{cardNumber}/comments/{commentId}" as never, {
        params: { path: { cardNumber, commentId } },
      } as never),
    );
  }

  /**
   * UpdateComment
   */
  async update(cardNumber: number, commentId: string, body: UpdateCommentRequest): Promise<Comment> {
    return this.request(
      {
        service: "Comment",
        operation: "UpdateComment",
        resourceType: "comment",
        isMutation: true,
      },
      () => this.client.PATCH("/cards/{cardNumber}/comments/{commentId}" as never, {
        params: { path: { cardNumber, commentId } },
        body: { body: body.body } as never,
      } as never),
    );
  }
}
