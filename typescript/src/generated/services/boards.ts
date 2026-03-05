/**
 * Boards service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export type Board = components["schemas"]["Board"];

export interface CreateBoardRequest {
  /** Display name */
  name: string;
  /** Rich text description (HTML) */
  description?: string;
}

export interface UpdateBoardRequest {
  /** Display name */
  name?: string;
  /** Rich text description (HTML) */
  description?: string;
}

export class BoardsService extends BaseService {

  /**
   * List all boards.
   */
  async list(options?: PaginationOptions): Promise<ListResult<Board>> {
    return this.requestPaginated(
      {
        service: "Boards",
        operation: "List",
        resourceType: "board",
        isMutation: false,
      },
      () => this.client.GET("/boards.json" as never, {} as never),
      options,
    );
  }

  /**
   * Create a new board.
   */
  async create(body: CreateBoardRequest): Promise<Board> {
    return this.request(
      {
        service: "Boards",
        operation: "Create",
        resourceType: "board",
        isMutation: true,
      },
      () => this.client.POST("/boards.json" as never, {
        body: { name: body.name, description: body.description } as never,
      } as never),
    );
  }

  /**
   * Get a single board by ID.
   */
  async get(boardId: number): Promise<Board> {
    return this.request(
      {
        service: "Boards",
        operation: "Get",
        resourceType: "board",
        isMutation: false,
        boardId,
      },
      () => this.client.GET("/boards/{boardId}.json" as never, {
        params: { path: { boardId } },
      } as never),
    );
  }

  /**
   * Update a board.
   */
  async update(boardId: number, body: UpdateBoardRequest): Promise<Board> {
    return this.request(
      {
        service: "Boards",
        operation: "Update",
        resourceType: "board",
        isMutation: true,
        boardId,
      },
      () => this.client.PUT("/boards/{boardId}.json" as never, {
        params: { path: { boardId } },
        body: { name: body.name, description: body.description } as never,
      } as never),
    );
  }

  /**
   * Delete a board. Deleted boards cannot be recovered.
   */
  async delete(boardId: number): Promise<void> {
    return this.request(
      {
        service: "Boards",
        operation: "Delete",
        resourceType: "board",
        isMutation: true,
        boardId,
      },
      () => this.client.DELETE("/boards/{boardId}.json" as never, {
        params: { path: { boardId } },
      } as never),
    );
  }
}
