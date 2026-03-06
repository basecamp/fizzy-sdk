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
  /** Color value */
  color?: string;
}

export interface UpdateColumnRequest {
  /** Display name */
  name?: string;
  /** Color value */
  color?: string;
}

export class ColumnsService extends BaseService {

  /**
   * ListColumns
   */
  async list(boardId: number): Promise<ListResult<Column>> {
    return this.request(
      {
        service: "Columns",
        operation: "ListColumns",
        resourceType: "columns",
        isMutation: false,
      },
      () => this.client.GET("/boards/{boardId}/columns.json" as never, {
        params: { path: { boardId } },
      } as never),
    );
  }

  /**
   * CreateColumn
   */
  async create(boardId: number, body: CreateColumnRequest): Promise<Column> {
    return this.request(
      {
        service: "Column",
        operation: "CreateColumn",
        resourceType: "column",
        isMutation: true,
      },
      () => this.client.POST("/boards/{boardId}/columns.json" as never, {
        params: { path: { boardId } },
        body: { name: body.name, color: body.color } as never,
      } as never),
    );
  }

  /**
   * GetColumn
   */
  async get(boardId: number, columnId: number): Promise<Column> {
    return this.request(
      {
        service: "Column",
        operation: "GetColumn",
        resourceType: "column",
        isMutation: false,
      },
      () => this.client.GET("/boards/{boardId}/columns/{columnId}" as never, {
        params: { path: { boardId, columnId } },
      } as never),
    );
  }

  /**
   * UpdateColumn
   */
  async update(boardId: number, columnId: number, body?: UpdateColumnRequest): Promise<Column> {
    return this.request(
      {
        service: "Column",
        operation: "UpdateColumn",
        resourceType: "column",
        isMutation: true,
      },
      () => this.client.PATCH("/boards/{boardId}/columns/{columnId}" as never, {
        params: { path: { boardId, columnId } },
        body: { name: body?.name, color: body?.color } as never,
      } as never),
    );
  }
}
