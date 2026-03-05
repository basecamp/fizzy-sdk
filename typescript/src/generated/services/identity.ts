/**
 * Identity service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import type { components } from "../schema.js";

export type Identity = components["schemas"]["Identity"];

export class IdentityService extends BaseService {

  /**
   * Get the authenticated user's identity.
   */
  async me(): Promise<Identity> {
    return this.request(
      {
        service: "Identity",
        operation: "Me",
        resourceType: "identity",
        isMutation: false,
      },
      () => this.client.GET("/me.json" as never, {} as never),
    );
  }
}
