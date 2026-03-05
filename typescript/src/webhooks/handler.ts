import { verifyWebhookSignature } from "./verify.js";

/** Webhook event — raw JSON object from Fizzy. */
export interface WebhookEvent {
  id?: number;
  kind?: string;
  [key: string]: unknown;
}

/** Handler function for webhook events. */
export type WebhookEventHandler = (event: WebhookEvent) => void | Promise<void>;

/** Middleware function that wraps event processing. Call next() to continue the chain. */
export type WebhookMiddleware = (event: WebhookEvent, next: () => Promise<void>) => Promise<void>;

/** Header accessor: either a record of headers or a function that retrieves a header by name. */
export type HeaderAccessor =
  | Record<string, string | string[] | undefined>
  | ((name: string) => string | undefined);

export interface WebhookReceiverOptions {
  /** HMAC secret for signature verification. If unset, verification is skipped. */
  secret?: string;
  /** HTTP header containing the signature (default: "x-fizzy-signature"). */
  signatureHeader?: string;
  /** Number of recent event IDs to track for deduplication (default: 1000, 0 to disable). */
  dedupWindowSize?: number;
}

/** Error thrown when webhook signature verification fails. */
export class WebhookVerificationError extends Error {
  constructor(message = "invalid webhook signature") {
    super(message);
    this.name = "WebhookVerificationError";
  }
}

/**
 * Receives and routes webhook events from Fizzy.
 *
 * Framework-agnostic: works with raw body bytes and a header accessor.
 */
export class WebhookReceiver {
  private readonly secret?: string;
  private readonly signatureHeader: string;
  private readonly dedupWindowSize: number;
  private readonly handlers = new Map<string, WebhookEventHandler[]>();
  private readonly anyHandlers: WebhookEventHandler[] = [];
  private readonly middlewareChain: WebhookMiddleware[] = [];
  private readonly dedupSeen = new Set<string>();
  private readonly dedupOrder: string[] = [];
  private readonly dedupPending = new Set<string>();

  constructor(options?: WebhookReceiverOptions) {
    this.secret = options?.secret;
    this.signatureHeader = options?.signatureHeader ?? "x-fizzy-signature";
    this.dedupWindowSize = options?.dedupWindowSize ?? 1000;
  }

  /**
   * Register a handler for a specific event kind pattern.
   * Supports exact match ("card_created") and glob patterns ("card_*", "*_created").
   */
  on(pattern: string, handler: WebhookEventHandler): this {
    const existing = this.handlers.get(pattern);
    if (existing) {
      existing.push(handler);
    } else {
      this.handlers.set(pattern, [handler]);
    }
    return this;
  }

  /** Register a handler that fires for all events. */
  onAny(handler: WebhookEventHandler): this {
    this.anyHandlers.push(handler);
    return this;
  }

  /** Add middleware to the processing chain. */
  use(middleware: WebhookMiddleware): this {
    this.middlewareChain.push(middleware);
    return this;
  }

  /**
   * Process a raw webhook request.
   * Returns the parsed WebhookEvent.
   * @throws {WebhookVerificationError} if signature verification fails
   */
  async handleRequest(
    rawBody: string | Buffer,
    headers: HeaderAccessor,
  ): Promise<WebhookEvent> {
    if (this.secret) {
      const sig = this.getHeader(headers, this.signatureHeader);
      if (!sig || !verifyWebhookSignature(rawBody, sig, this.secret)) {
        throw new WebhookVerificationError();
      }
    }

    const bodyStr = typeof rawBody === "string" ? rawBody : rawBody.toString("utf8");
    const eventIdStr = extractIdString(bodyStr);
    const event: WebhookEvent = JSON.parse(bodyStr);

    if (!this.claim(eventIdStr)) {
      return event;
    }

    try {
      const runHandlers = async () => {
        await this.dispatchHandlers(event);
      };

      let chain = runHandlers;
      for (let i = this.middlewareChain.length - 1; i >= 0; i--) {
        const mw = this.middlewareChain[i]!;
        const next = chain;
        chain = () => mw(event, next);
      }

      await chain();
      this.commitSeen(eventIdStr);
    } catch (err) {
      this.releaseClaim(eventIdStr);
      throw err;
    }

    return event;
  }

  private getHeader(headers: HeaderAccessor, name: string): string | undefined {
    if (typeof headers === "function") {
      return headers(name);
    }
    const val = headers[name] ?? headers[name.toLowerCase()];
    if (Array.isArray(val)) return val[0];
    return val;
  }

  private claim(eventIdStr: string | undefined): boolean {
    if (this.dedupWindowSize <= 0 || !eventIdStr) return true;
    if (this.dedupSeen.has(eventIdStr) || this.dedupPending.has(eventIdStr)) return false;
    this.dedupPending.add(eventIdStr);
    return true;
  }

  private commitSeen(eventIdStr: string | undefined): void {
    if (this.dedupWindowSize <= 0 || !eventIdStr) return;
    this.dedupPending.delete(eventIdStr);

    if (this.dedupOrder.length >= this.dedupWindowSize) {
      const oldest = this.dedupOrder.shift()!;
      this.dedupSeen.delete(oldest);
    }

    this.dedupSeen.add(eventIdStr);
    this.dedupOrder.push(eventIdStr);
  }

  private releaseClaim(eventIdStr: string | undefined): void {
    if (eventIdStr) this.dedupPending.delete(eventIdStr);
  }

  private async dispatchHandlers(event: WebhookEvent): Promise<void> {
    const matched: WebhookEventHandler[] = [];

    for (const [pattern, handlers] of this.handlers) {
      if (matchPattern(pattern, event.kind ?? "")) {
        matched.push(...handlers);
      }
    }

    matched.push(...this.anyHandlers);

    for (const handler of matched) {
      await handler(event);
    }
  }
}

/** Extract "id" as raw string from JSON to avoid int64 precision loss. */
function extractIdString(json: string): string | undefined {
  let depth = 0;
  let inString = false;

  for (let i = 0; i < json.length; i++) {
    const ch = json[i];

    if (inString) {
      if (ch === "\\") { i++; continue; }
      if (ch === '"') { inString = false; }
      continue;
    }

    if (ch === '"') {
      if (depth === 1 && json[i + 1] === "i" && json[i + 2] === "d" && json[i + 3] === '"') {
        let j = i + 4;
        while (j < json.length && (json[j] === " " || json[j] === "\t" || json[j] === "\n" || json[j] === "\r" || json[j] === ":")) j++;
        const start = j;
        while (j < json.length && json[j]! >= "0" && json[j]! <= "9") j++;
        if (j > start) return json.slice(start, j);
      }
      inString = true;
      continue;
    }

    if (ch === "{") { depth++; continue; }
    if (ch === "}") { depth--; continue; }
  }
  return undefined;
}

/**
 * Match a webhook event kind against a glob pattern.
 * "*" matches any sequence of characters.
 */
function matchPattern(pattern: string, value: string): boolean {
  if (pattern === value) return true;

  const parts = pattern.split("*");
  if (parts.length === 1) return false;

  let remaining = value;
  for (let i = 0; i < parts.length; i++) {
    const part = parts[i]!;
    if (part === "") continue;

    const idx = remaining.indexOf(part);
    if (idx === -1) return false;
    if (i === 0 && idx !== 0) return false;
    remaining = remaining.slice(idx + part.length);
  }

  const lastPart = parts.at(-1)!;
  if (lastPart !== "") {
    return value.endsWith(lastPart);
  }

  return true;
}
