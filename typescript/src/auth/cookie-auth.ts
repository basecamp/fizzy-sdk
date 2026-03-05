/**
 * Cookie-based authentication strategy for the Fizzy SDK.
 *
 * CookieAuth sets the Cookie header for session-based authentication,
 * used by mobile and web clients.
 */

import type { AuthStrategy } from "../auth-strategy.js";

/**
 * Provider for cookie values — either a static string or an async function.
 */
export type CookieProvider = string | (() => Promise<string>);

/**
 * Cookie-based authentication strategy.
 * Sets the Cookie header with the provided session cookie.
 */
export class CookieAuth implements AuthStrategy {
  private cookieProvider: CookieProvider;

  constructor(cookieProvider: CookieProvider) {
    this.cookieProvider = cookieProvider;
  }

  async authenticate(headers: Headers): Promise<void> {
    const cookie =
      typeof this.cookieProvider === "function"
        ? await this.cookieProvider()
        : this.cookieProvider;
    headers.set("Cookie", cookie);
  }
}

/**
 * Creates a CookieAuth strategy from a CookieProvider.
 */
export function cookieAuth(cookieProvider: CookieProvider): AuthStrategy {
  return new CookieAuth(cookieProvider);
}
