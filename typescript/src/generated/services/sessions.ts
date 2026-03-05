/**
 * Sessions service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import type { components } from "../schema.js";

export type Session = components["schemas"]["Session"];

export interface CreateSessionRequest {
  /** Email address for magic link delivery */
  email: string;
}

export interface RedeemMagicLinkRequest {
  /** Magic link token */
  token: string;
}

export interface CompleteSignupRequest {
  /** Display name */
  name: string;
  /** Magic link token */
  token: string;
}

export class SessionsService extends BaseService {

  async create(body: CreateSessionRequest): Promise<void> {
    return this.request(
      { service: "Sessions", operation: "CreateSession", resourceType: "session", isMutation: true },
      () => this.client.POST("/session.json" as never, {
        body: { email: body.email } as never,
      } as never),
    );
  }

  async redeemMagicLink(body: RedeemMagicLinkRequest): Promise<Session> {
    return this.request(
      { service: "Sessions", operation: "RedeemMagicLink", resourceType: "session", isMutation: true },
      () => this.client.POST("/session/magic_link.json" as never, {
        body: { token: body.token } as never,
      } as never),
    );
  }

  async destroy(): Promise<void> {
    return this.request(
      { service: "Sessions", operation: "DestroySession", resourceType: "session", isMutation: true },
      () => this.client.DELETE("/session.json" as never, {} as never),
    );
  }

  async completeSignup(body: CompleteSignupRequest): Promise<Session> {
    return this.request(
      { service: "Sessions", operation: "CompleteSignup", resourceType: "session", isMutation: true },
      () => this.client.POST("/signup/completion.json" as never, {
        body: { name: body.name, token: body.token } as never,
      } as never),
    );
  }
}
