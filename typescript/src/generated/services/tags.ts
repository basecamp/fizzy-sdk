/**
 * Tags service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export type Tag = components["schemas"]["Tag"];

export class TagsService extends BaseService {

  /**
   * ListTags
   */
  async list(options?: PaginationOptions): Promise<ListResult<Tag>> {
    return this.requestPaginated(
      {
        service: "Tags",
        operation: "ListTags",
        resourceType: "tags",
        isMutation: false,
      },
      () => this.client.GET("/tags.json" as never, {
      } as never),
      options,
    );
  }
}
