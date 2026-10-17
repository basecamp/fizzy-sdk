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
  /** The code from the magic-link email. */
  code: string;
}

export interface CompleteSignupRequest {
  fullName: string;
}

export interface CompleteJoinRequest {
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
   * Starts a magic-link sign-in and answers the pending authentication token.

Fizzy answers 201 and also sets the token as the pending_authentication_token cookie, which
RedeemMagicLink reads.
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
   * Redeems the code from a magic-link email for a session token.

Fizzy reads the pending sign-in from the pending_authentication_token cookie CreateSession
set, not from the body, so the request must carry it as
`Cookie: pending_authentication_token=<token>`. The session_token it answers is sent back as
`Cookie: session_token=<token>`.
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
        body: { code: body.code } as never,
      } as never),
    );
  }

  /**
   * CompleteSignup
   */
  async completeSignup(body: CompleteSignupRequest): Promise<void> {
    return this.request(
      {
        service: "Signup",
        operation: "CompleteSignup",
        resourceType: "signup",
        isMutation: true,
      },
      () => this.client.POST("/signup/completion.json" as never, {
        body: { full_name: body.fullName } as never,
      } as never),
    );
  }

  /**
   * CompleteJoin
   */
  async completeJoin(body: CompleteJoinRequest): Promise<void> {
    return this.request(
      {
        service: "Join",
        operation: "CompleteJoin",
        resourceType: "join",
        isMutation: true,
      },
      () => this.client.POST("/users/joins.json" as never, {
        body: { name: body.name } as never,
      } as never),
    );
  }
}
