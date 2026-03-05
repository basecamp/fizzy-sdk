/**
 * Magic-link passwordless login flow for the Fizzy SDK.
 *
 * Two-step orchestrator:
 * 1. CreateSession — sends a magic link to the user's email
 * 2. RedeemMagicLink — exchanges the magic link token for a session
 */

import type { AuthStrategy } from "../auth-strategy.js";
import { FizzyError } from "../errors.js";

/**
 * Result of the magic link request step.
 */
export interface MagicLinkRequestResult {
  /** Whether the magic link email was sent successfully */
  sent: boolean;
  /** User-facing message (e.g., "Check your email") */
  message: string;
}

/**
 * Result of the magic link redemption step.
 */
export interface MagicLinkRedeemResult {
  /** The session token to use for subsequent requests */
  sessionToken: string;
  /** The authentication strategy configured with the session */
  auth: AuthStrategy;
}

/**
 * Options for the magic link flow.
 */
export interface MagicLinkFlowOptions {
  /** Base URL of the Fizzy API (defaults to https://fizzy.do) */
  baseUrl?: string;
  /** User-Agent header for requests */
  userAgent?: string;
}

/**
 * Orchestrates the magic-link passwordless login flow.
 *
 * @example
 * ```ts
 * const flow = new MagicLinkFlow();
 *
 * // Step 1: Request the magic link
 * const { sent } = await flow.requestLink("user@example.com");
 *
 * // Step 2: User clicks the link, you capture the token
 * const { auth } = await flow.redeemToken(token);
 *
 * // Step 3: Use the auth strategy with the client
 * const client = createFizzyClient({ auth });
 * ```
 */
export class MagicLinkFlow {
  private readonly baseUrl: string;
  private readonly userAgent: string;

  constructor(options?: MagicLinkFlowOptions) {
    this.baseUrl = options?.baseUrl ?? "https://fizzy.do";
    this.userAgent = options?.userAgent ?? "fizzy-sdk-ts/0.1.0";
  }

  /**
   * Step 1: Request a magic link be sent to the user's email.
   */
  async requestLink(email: string): Promise<MagicLinkRequestResult> {
    const response = await fetch(`${this.baseUrl}/sessions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "User-Agent": this.userAgent,
        Accept: "application/json",
      },
      body: JSON.stringify({ email }),
    });

    if (!response.ok) {
      throw new FizzyError(
        "api_error",
        `Magic link request failed: ${response.status} ${response.statusText}`,
        { httpStatus: response.status },
      );
    }

    return { sent: true, message: "Check your email for the magic link" };
  }

  /**
   * Step 2: Redeem a magic link token for a session.
   */
  async redeemToken(token: string): Promise<MagicLinkRedeemResult> {
    const response = await fetch(`${this.baseUrl}/sessions/redeem`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "User-Agent": this.userAgent,
        Accept: "application/json",
      },
      body: JSON.stringify({ token }),
    });

    if (!response.ok) {
      throw new FizzyError(
        "auth_required",
        `Magic link redemption failed: ${response.status} ${response.statusText}`,
        { httpStatus: response.status, hint: "The magic link may have expired. Request a new one." },
      );
    }

    const body = await response.json() as { session_token?: string; token?: string };
    const sessionToken = body.session_token ?? body.token;

    if (!sessionToken || typeof sessionToken !== "string") {
      throw new FizzyError("api_error", "No session token in magic link response");
    }

    // Import CookieAuth dynamically to avoid circular dependency at module level
    const { CookieAuth } = await import("./cookie-auth.js");
    const auth = new CookieAuth(sessionToken);

    return { sessionToken, auth };
  }
}
