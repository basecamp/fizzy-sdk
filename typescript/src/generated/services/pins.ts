/**
 * Pins service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export type Pin = components["schemas"]["Pin"];

export class PinsService extends BaseService {

  /**
   * ListPins
   */
  async list(): Promise<ListResult<Pin>> {
    return this.request(
      {
        service: "Pins",
        operation: "ListPins",
        resourceType: "pins",
        isMutation: false,
      },
      () => this.client.GET("/my/pins.json" as never, {
      } as never),
    );
  }
}
