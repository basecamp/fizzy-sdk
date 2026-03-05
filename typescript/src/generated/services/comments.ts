/**
 * Comments service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export type Comment = components["schemas"]["Comment"];

export interface CreateCommentRequest {
  /** Body content (Markdown or HTML) */
  body: string;
}

export interface UpdateCommentRequest {
  /** Body content (Markdown or HTML) */
  body?: string;
}

export class CommentsService extends BaseService {

  async list(cardNumber: number, options?: PaginationOptions): Promise<ListResult<Comment>> {
    return this.requestPaginated(
      { service: "Comments", operation: "List", resourceType: "comment", isMutation: false },
      () => this.client.GET("/cards/{cardNumber}/comments.json" as never, {
        params: { path: { cardNumber } },
      } as never),
      options,
    );
  }

  async create(cardNumber: number, body: CreateCommentRequest): Promise<Comment> {
    return this.request(
      { service: "Comments", operation: "Create", resourceType: "comment", isMutation: true },
      () => this.client.POST("/cards/{cardNumber}/comments.json" as never, {
        params: { path: { cardNumber } },
        body: { body: body.body } as never,
      } as never),
    );
  }

  async get(cardNumber: number, commentId: number): Promise<Comment> {
    return this.request(
      { service: "Comments", operation: "Get", resourceType: "comment", isMutation: false, resourceId: commentId },
      () => this.client.GET("/cards/{cardNumber}/comments/{commentId}.json" as never, {
        params: { path: { cardNumber, commentId } },
      } as never),
    );
  }

  async update(cardNumber: number, commentId: number, body: UpdateCommentRequest): Promise<Comment> {
    return this.request(
      { service: "Comments", operation: "Update", resourceType: "comment", isMutation: true, resourceId: commentId },
      () => this.client.PUT("/cards/{cardNumber}/comments/{commentId}.json" as never, {
        params: { path: { cardNumber, commentId } },
        body: { body: body.body } as never,
      } as never),
    );
  }

  async delete(cardNumber: number, commentId: number): Promise<void> {
    return this.request(
      { service: "Comments", operation: "Delete", resourceType: "comment", isMutation: true, resourceId: commentId },
      () => this.client.DELETE("/cards/{cardNumber}/comments/{commentId}.json" as never, {
        params: { path: { cardNumber, commentId } },
      } as never),
    );
  }
}
