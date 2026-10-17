/**
 * Identity service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import type { components } from "../schema.js";

export type Identity = components["schemas"]["Identity"];

export interface UpdateMyTimezoneRequest {
  /** An IANA or Rails time zone name, such as "America/Chicago" or "Central Time (US & Canada)". */
  timezoneName: string;
}

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

  /**
   * Sets the caller's time zone. The name isn't validated: one that ActiveSupport::TimeZone doesn't recognize is stored, succeeds with 204, and reads back as UTC.
   */
  async updateTimezone(body: UpdateMyTimezoneRequest): Promise<void> {
    return this.request(
      {
        service: "My timezone",
        operation: "UpdateMyTimezone",
        resourceType: "my_timezone",
        isMutation: true,
      },
      () => this.client.PATCH("/my/timezone.json" as never, {
        body: { timezone_name: body.timezoneName } as never,
      } as never),
    );
  }
}
