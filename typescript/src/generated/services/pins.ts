/**
 * Pins service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export type Pin = components["schemas"]["Pin"];

export class PinsService extends BaseService {

  async list(options?: PaginationOptions): Promise<ListResult<Pin>> {
    return this.requestPaginated(
      { service: "Pins", operation: "List", resourceType: "pin", isMutation: false },
      () => this.client.GET("/pins.json" as never, {} as never),
      options,
    );
  }
}
