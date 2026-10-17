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
  /** The column color, as its CSS value: "var(--color-card-default)" (Blue), "var(--color-card-1)" (Gray), "var(--color-card-2)" (Tan), "var(--color-card-3)" (Yellow), "var(--color-card-4)" (Lime), "var(--color-card-5)" (Aqua), "var(--color-card-6)" (Violet), "var(--color-card-7)" (Purple) or "var(--color-card-8)" (Pink) (Color::COLORS). Any other value is stored but reads back as Blue. */
  color?: string;
}

export interface UpdateColumnRequest {
  /** Display name */
  name?: string;
  /** The column color, as its CSS value: "var(--color-card-default)" (Blue), "var(--color-card-1)" (Gray), "var(--color-card-2)" (Tan), "var(--color-card-3)" (Yellow), "var(--color-card-4)" (Lime), "var(--color-card-5)" (Aqua), "var(--color-card-6)" (Violet), "var(--color-card-7)" (Purple) or "var(--color-card-8)" (Pink) (Color::COLORS). Any other value is stored but reads back as Blue. */
  color?: string;
}

export class ColumnsService extends BaseService {

  /**
   * ListColumns
   */
  async list(boardId: string): Promise<ListResult<Column>> {
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
  async create(boardId: string, body: CreateColumnRequest): Promise<Column> {
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
   * DeleteColumn
   */
  async delete(boardId: string, columnId: string): Promise<void> {
    return this.request(
      {
        service: "Column",
        operation: "DeleteColumn",
        resourceType: "column",
        isMutation: true,
      },
      () => this.client.DELETE("/boards/{boardId}/columns/{columnId}" as never, {
        params: { path: { boardId, columnId } },
      } as never),
    );
  }

  /**
   * GetColumn
   */
  async get(boardId: string, columnId: string): Promise<Column> {
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
   * Updates a column. Send at least one of name or color: the controller expects a `column` object, so an empty body is a 400.
   */
  async update(boardId: string, columnId: string, body?: UpdateColumnRequest): Promise<Column> {
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
