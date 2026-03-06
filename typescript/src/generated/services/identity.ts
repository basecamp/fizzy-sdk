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
   * GetMyIdentity
   */
  async me(): Promise<Identity> {
    return this.request(
      {
        service: "My identity",
        operation: "GetMyIdentity",
        resourceType: "my_identity",
        isMutation: false,
      },
      () => this.client.GET("/my/identity.json" as never, {
      } as never),
    );
  }
}
