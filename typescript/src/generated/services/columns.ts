/**
 * Columns service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export type Column = components["schemas"]["Column"];

export interface CreateColumnRequest {
  /** Display name */
  name: string;
  /** Position for ordering (1-based) */
  position?: number;
}

export interface UpdateColumnRequest {
  /** Display name */
  name?: string;
  /** Position for ordering (1-based) */
  position?: number;
}

export class ColumnsService extends BaseService {

  /**
   * List all columns for a board.
   */
  async list(boardId: number, options?: PaginationOptions): Promise<ListResult<Column>> {
    return this.requestPaginated(
      {
        service: "Columns",
        operation: "List",
        resourceType: "column",
        isMutation: false,
        boardId,
      },
      () => this.client.GET("/boards/{boardId}/columns.json" as never, {
        params: { path: { boardId } },
      } as never),
      options,
    );
  }

  /**
   * Create a new column on a board.
   */
  async create(boardId: number, body: CreateColumnRequest): Promise<Column> {
    return this.request(
      {
        service: "Columns",
        operation: "Create",
        resourceType: "column",
        isMutation: true,
        boardId,
      },
      () => this.client.POST("/boards/{boardId}/columns.json" as never, {
        params: { path: { boardId } },
        body: { name: body.name, position: body.position } as never,
      } as never),
    );
  }

  /**
   * Get a single column.
   */
  async get(boardId: number, columnId: number): Promise<Column> {
    return this.request(
      {
        service: "Columns",
        operation: "Get",
        resourceType: "column",
        isMutation: false,
        boardId,
      },
      () => this.client.GET("/boards/{boardId}/columns/{columnId}.json" as never, {
        params: { path: { boardId, columnId } },
      } as never),
    );
  }

  /**
   * Update a column.
   */
  async update(boardId: number, columnId: number, body: UpdateColumnRequest): Promise<Column> {
    return this.request(
      {
        service: "Columns",
        operation: "Update",
        resourceType: "column",
        isMutation: true,
        boardId,
      },
      () => this.client.PUT("/boards/{boardId}/columns/{columnId}.json" as never, {
        params: { path: { boardId, columnId } },
        body: { name: body.name, position: body.position } as never,
      } as never),
    );
  }
}
