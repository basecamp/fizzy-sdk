/**
 * Magic-link passwordless sign-in for the Fizzy SDK.
 *
 * Fizzy's sign-in is three requests, each a generated operation:
 * 1. CreateSession (`POST /session.json`, `{email_address}`) emails a code and answers 201
 *    with the pending authentication token.
 * 2. RedeemMagicLink (`POST /session/magic_link.json`, `{code}`) exchanges the code for a
 *    session token. Fizzy reads the pending sign-in from the `pending_authentication_token`
 *    cookie, not the body, so the flow sends that cookie itself.
 * 3. CompleteSignup (`POST /signup/completion.json`, `{full_name}`) finishes a new account,
 *    when the redemption says one needs it.
 *
 * Every request goes through a client from {@link createFizzyClient}, so HTTPS enforcement,
 * body limits, error mapping and hooks are the client's own.
 */

import type { AuthStrategy } from "../auth-strategy.js";
import { createFizzyClient, type FizzyClient, type FizzyClientOptions } from "../client.js";
import { FizzyError } from "../errors.js";
import { CookieAuth } from "./cookie-auth.js";

/** The cookie a pending sign-in is carried in between creating the session and redeeming the code. */
const PENDING_COOKIE = "pending_authentication_token";
/** The cookie a session token is sent back in. */
const SESSION_COOKIE = "session_token";

/**
 * A `Cookie` header value carrying one cookie, its value percent-encoded as Rack decodes it.
 */
export function cookieHeader(name: string, value: string): string {
  return `${name}=${encodeURIComponent(value)}`;
}

/** What creating a session answers. */
export interface MagicLinkRequestResult {
  /**
   * The token the pending sign-in waits on. The flow keeps it for {@link MagicLinkFlow.redeem};
   * a caller that finishes the sign-in in another process hands it to
   * {@link MagicLinkFlow.resume} there.
   */
  pendingAuthenticationToken: string;
}

/** What redeeming a code answers. */
export interface MagicLinkRedeemResult {
  /** The session token, sent back as the `session_token` cookie. */
  sessionToken: string;
  /** Whether the account is new and needs {@link MagicLinkFlow.completeSignup} before use. */
  requiresSignupCompletion: boolean;
  /** An authentication strategy that sends the session cookie, for {@link createFizzyClient}. */
  auth: AuthStrategy;
}

/** Options for the magic link flow: the client options that apply before there is a credential. */
export type MagicLinkFlowOptions = Pick<
  FizzyClientOptions,
  "baseUrl" | "userAgent" | "requestTimeoutMs" | "hooks"
>;

/** Sends no credential: there is none yet when a sign-in starts. */
const noCredentials: AuthStrategy = { authenticate: async () => {} };

/**
 * Orchestrates Fizzy's magic-link sign-in.
 *
 * @example
 * ```ts
 * const flow = new MagicLinkFlow();
 *
 * // Step 1: Fizzy emails a code
 * await flow.createSession("user@example.com");
 *
 * // Step 2: the user types the code in
 * const { auth, requiresSignupCompletion } = await flow.redeem(code);
 * if (requiresSignupCompletion) await flow.completeSignup("Ada Lovelace");
 *
 * // Step 3: use the session
 * const client = createFizzyClient({ auth });
 * ```
 */
export class MagicLinkFlow {
  private readonly options: MagicLinkFlowOptions;
  private pending: string | undefined;
  private session: string | undefined;

  constructor(options?: MagicLinkFlowOptions) {
    this.options = options ?? {};
  }

  /**
   * A flow that picks up where another left off, with the pending token that one handed out
   * through {@link MagicLinkFlow.pendingToken}.
   */
  static resume(pendingToken: string, options?: MagicLinkFlowOptions): MagicLinkFlow {
    const flow = new MagicLinkFlow(options);
    flow.pending = pendingToken;
    return flow;
  }

  /** The token the pending sign-in waits on, for a caller that finishes the flow elsewhere. */
  get pendingToken(): string | undefined {
    return this.pending;
  }

  /**
   * Asks Fizzy to email a sign-in code to the address, and keeps the pending token its 201
   * answer carries for {@link MagicLinkFlow.redeem}.
   */
  async createSession(emailAddress: string): Promise<MagicLinkRequestResult> {
    const answer = await this.client(noCredentials).sessions.create({ emailAddress });
    const token = answer?.pending_authentication_token;
    if (typeof token !== "string" || token === "") {
      throw new FizzyError("api_error", "No pending authentication token in the session response");
    }
    this.pending = token;
    return { pendingAuthenticationToken: token };
  }

  /**
   * Sends the code back with the pending token as its cookie, and answers the session Fizzy
   * signed in. Without a pending token, from {@link MagicLinkFlow.createSession} or
   * {@link MagicLinkFlow.resume}, there is nothing to redeem against.
   */
  async redeem(code: string): Promise<MagicLinkRedeemResult> {
    if (!this.pending) {
      throw new FizzyError("usage", "No sign-in is pending", {
        hint: "Call createSession first, or resume with the pending token",
      });
    }
    const pending = this.pending;
    const pendingCookie = new CookieAuth(cookieHeader(PENDING_COOKIE, pending));
    const answer = await this.client(pendingCookie).sessions.redeemMagicLink({ code });
    const sessionToken = answer?.session_token;
    if (typeof sessionToken !== "string" || sessionToken === "") {
      throw new FizzyError("api_error", "No session token in the magic link response");
    }
    this.session = sessionToken;
    // The sign-in redeemed is consumed; one a createSession started meanwhile is not.
    if (this.pending === pending) this.pending = undefined;
    return {
      sessionToken,
      requiresSignupCompletion: answer.requires_signup_completion === true,
      auth: new CookieAuth(cookieHeader(SESSION_COOKIE, sessionToken)),
    };
  }

  /**
   * Finishes a new account's sign-up under the session {@link MagicLinkFlow.redeem} answered,
   * or the session token given. Fizzy answers 201 with no body.
   */
  async completeSignup(fullName: string, sessionToken?: string): Promise<void> {
    const token = sessionToken ?? this.session;
    if (!token) {
      throw new FizzyError("usage", "No session to complete the sign-up under", {
        hint: "Redeem the code first, or pass the session token",
      });
    }
    await this.client(new CookieAuth(cookieHeader(SESSION_COOKIE, token))).sessions.completeSignup({ fullName });
  }

  private client(auth: AuthStrategy): FizzyClient {
    return createFizzyClient({ ...this.options, auth });
  }
}
