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
  allAccess?: boolean;
  autoPostponePeriod?: number;
}

export interface UpdateBoardRequest {
  /** Display name */
  name?: string;
  allAccess?: boolean;
  autoPostponePeriod?: number;
}

export class BoardsService extends BaseService {

  /**
   * ListBoards
   */
  async list(options?: PaginationOptions): Promise<ListResult<Board>> {
    return this.requestPaginated(
      {
        service: "Boards",
        operation: "ListBoards",
        resourceType: "boards",
        isMutation: false,
      },
      () => this.client.GET("/boards.json" as never, {
      } as never),
      options,
    );
  }

  /**
   * CreateBoard
   */
  async create(body: CreateBoardRequest): Promise<Board> {
    return this.request(
      {
        service: "Board",
        operation: "CreateBoard",
        resourceType: "board",
        isMutation: true,
      },
      () => this.client.POST("/boards.json" as never, {
        body: { name: body.name, all_access: body.allAccess, auto_postpone_period: body.autoPostponePeriod } as never,
      } as never),
    );
  }

  /**
   * DeleteBoard
   */
  async delete(boardId: string): Promise<void> {
    return this.request(
      {
        service: "Board",
        operation: "DeleteBoard",
        resourceType: "board",
        isMutation: true,
      },
      () => this.client.DELETE("/boards/{boardId}" as never, {
        params: { path: { boardId } },
      } as never),
    );
  }

  /**
   * GetBoard
   */
  async get(boardId: string): Promise<Board> {
    return this.request(
      {
        service: "Board",
        operation: "GetBoard",
        resourceType: "board",
        isMutation: false,
      },
      () => this.client.GET("/boards/{boardId}" as never, {
        params: { path: { boardId } },
      } as never),
    );
  }

  /**
   * UpdateBoard
   */
  async update(boardId: string, body?: UpdateBoardRequest): Promise<Board> {
    return this.request(
      {
        service: "Board",
        operation: "UpdateBoard",
        resourceType: "board",
        isMutation: true,
      },
      () => this.client.PATCH("/boards/{boardId}" as never, {
        params: { path: { boardId } },
        body: { name: body?.name, all_access: body?.allAccess, auto_postpone_period: body?.autoPostponePeriod } as never,
      } as never),
    );
  }
}
