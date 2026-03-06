/**
 * Sessions service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import type { components } from "../schema.js";

export interface CreateSessionRequest {
  emailAddress: string;
}

export interface RedeemMagicLinkRequest {
  token: string;
}

export interface CompleteSignupRequest {
  /** Display name */
  name: string;
}

export class SessionsService extends BaseService {

  /**
   * DestroySession
   */
  async destroy(): Promise<void> {
    return this.request(
      {
        service: "Session",
        operation: "DestroySession",
        resourceType: "session",
        isMutation: true,
      },
      () => this.client.DELETE("/session.json" as never, {
      } as never),
    );
  }

  /**
   * CreateSession
   */
  async create(body: CreateSessionRequest): Promise<components["schemas"]["PendingAuthentication"]> {
    return this.request(
      {
        service: "Session",
        operation: "CreateSession",
        resourceType: "session",
        isMutation: true,
      },
      () => this.client.POST("/session.json" as never, {
        body: { email_address: body.emailAddress } as never,
      } as never),
    );
  }

  /**
   * RedeemMagicLink
   */
  async redeemMagicLink(body: RedeemMagicLinkRequest): Promise<components["schemas"]["SessionAuthorization"]> {
    return this.request(
      {
        service: "Magic link",
        operation: "RedeemMagicLink",
        resourceType: "magic_link",
        isMutation: true,
      },
      () => this.client.POST("/session/magic_link.json" as never, {
        body: { token: body.token } as never,
      } as never),
    );
  }

  /**
   * CompleteSignup
   */
  async completeSignup(body: CompleteSignupRequest): Promise<components["schemas"]["User"]> {
    return this.request(
      {
        service: "Signup",
        operation: "CompleteSignup",
        resourceType: "signup",
        isMutation: true,
      },
      () => this.client.POST("/signup/completion.json" as never, {
        body: { name: body.name } as never,
      } as never),
    );
  }
}
