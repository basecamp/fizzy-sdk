/**
 * Authentication strategy for the Fizzy SDK.
 *
 * AuthStrategy controls how authentication is applied to HTTP requests.
 * Fizzy supports Bearer tokens and Cookie sessions.
 */

import type { TokenProvider } from "./client.js";

/**
 * AuthStrategy controls how authentication is applied to HTTP requests.
 * Called before every HTTP request to apply credentials to headers.
 */
export interface AuthStrategy {
  /**
   * Apply authentication to the given request headers.
   * Called before every HTTP request.
   */
  authenticate(headers: Headers): Promise<void>;
}

/**
 * Bearer token authentication strategy.
 * Sets the Authorization header with "Bearer {token}".
 */
export class BearerAuth implements AuthStrategy {
  private tokenProvider: TokenProvider;

  constructor(tokenProvider: TokenProvider) {
    this.tokenProvider = tokenProvider;
  }

  async authenticate(headers: Headers): Promise<void> {
    const token =
      typeof this.tokenProvider === "function"
        ? await this.tokenProvider()
        : this.tokenProvider;
    headers.set("Authorization", `Bearer ${token}`);
  }
}

/**
 * Creates a BearerAuth strategy from a TokenProvider.
 */
export function bearerAuth(tokenProvider: TokenProvider): AuthStrategy {
  return new BearerAuth(tokenProvider);
}
