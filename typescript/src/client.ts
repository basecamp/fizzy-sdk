/**
 * Fizzy TypeScript SDK Client
 *
 * Creates a type-safe client for the Fizzy API using openapi-fetch.
 * Includes middleware for authentication, retry with exponential backoff,
 * ETag-based caching, and account scoping via forAccount().
 */

import createClient, { type Middleware } from "openapi-fetch";
import { createRequire } from "node:module";
import type { paths } from "./generated/schema.js";
import { PATH_TO_OPERATION } from "./generated/path-mapping.js";
import type { FizzyHooks, RequestInfo, RequestResult } from "./hooks.js";
import { FizzyError } from "./errors.js";
import { isLocalhost } from "./security.js";
import { parseNextLink, resolveURL, isSameOrigin } from "./pagination-utils.js";
import { type AuthStrategy, bearerAuth } from "./auth-strategy.js";
import { ETagCache } from "./cache/etag-cache.js";
import { BoardsService } from "./generated/services/boards.js";
import { CardsService } from "./generated/services/cards.js";
import { ColumnsService } from "./generated/services/columns.js";
import { CommentsService } from "./generated/services/comments.js";
import { DevicesService } from "./generated/services/devices.js";
import { IdentityService } from "./generated/services/identity.js";
import { NotificationsService } from "./generated/services/notifications.js";
import { PinsService } from "./generated/services/pins.js";
import { ReactionsService } from "./generated/services/reactions.js";
import { SessionsService } from "./generated/services/sessions.js";
import { StepsService } from "./generated/services/steps.js";
import { TagsService } from "./generated/services/tags.js";
import { UploadsService } from "./generated/services/uploads.js";
import { UsersService } from "./generated/services/users.js";
import { WebhooksService } from "./generated/services/webhooks.js";

const require = createRequire(import.meta.url);
const metadata = require("./generated/metadata.json") as OperationMetadata;

// Re-export types for consumer convenience
export type { paths };

/**
 * Raw client type from openapi-fetch.
 */
export type RawClient = ReturnType<typeof createClient<paths>>;

/**
 * Enhanced Fizzy client with hooks support and service accessors.
 */
export interface FizzyClient extends RawClient {
  readonly raw: RawClient;
  readonly hooks?: FizzyHooks;

  /**
   * Returns a new client scoped to the given account ID.
   * The new client shares auth strategy, hooks, and settings but
   * targets a different account URL prefix.
   */
  forAccount(accountId: string): FizzyClient;

  // Service accessors — generated services will be bound here by the factory.
  // The actual service types are added via defineService in createFizzyClient.
}

/**
 * Token provider — either a static token string or an async function that returns a token.
 */
export type TokenProvider = string | (() => Promise<string>);

/**
 * Configuration options for creating a Fizzy client.
 */
export interface FizzyClientOptions {
  /** Fizzy account ID (found in your Fizzy URL) */
  accountId?: string;
  /** Bearer access token or async function that returns one */
  accessToken?: TokenProvider;
  /** Authentication strategy (alternative to accessToken for custom auth schemes) */
  auth?: AuthStrategy;
  /** Base URL override (defaults to https://fizzy.do) */
  baseUrl?: string;
  /** User-Agent header (defaults to fizzy-sdk-ts/VERSION (api:API_VERSION)) */
  userAgent?: string;
  /** Enable ETag-based caching (defaults to false) */
  enableCache?: boolean;
  /** Enable automatic retry on 429/503 (defaults to true) */
  enableRetry?: boolean;
  /** Request timeout in milliseconds (defaults to 30000) */
  requestTimeoutMs?: number;
  /** Hooks for observability (logging, metrics, tracing) */
  hooks?: FizzyHooks;
}

export const VERSION = "0.1.0";
export const API_VERSION = "2026-03-01";
const DEFAULT_BASE_URL = "https://fizzy.do";
const DEFAULT_USER_AGENT = `fizzy-sdk-ts/${VERSION} (api:${API_VERSION})`;

/**
 * Creates a type-safe Fizzy API client with built-in middleware for:
 * - Authentication (Bearer token or Cookie session)
 * - Retry with exponential backoff (respects Retry-After header)
 * - ETag-based HTTP caching
 *
 * @example
 * ```ts
 * import { createFizzyClient } from "@basecamp/fizzy-sdk";
 *
 * const client = createFizzyClient({
 *   accessToken: process.env.FIZZY_TOKEN!,
 * });
 *
 * const { data, error } = await client.GET("/boards.json");
 * ```
 */
export function createFizzyClient(options: FizzyClientOptions): FizzyClient {
  const {
    accountId,
    accessToken,
    auth,
    baseUrl: baseUrlOption,
    userAgent = DEFAULT_USER_AGENT,
    enableCache = false,
    enableRetry = true,
    requestTimeoutMs = 30000,
    hooks,
  } = options;

  // Resolve base URL: if accountId provided, scope to that account
  const baseUrl = baseUrlOption ??
    (accountId ? `${DEFAULT_BASE_URL}/${accountId}` : DEFAULT_BASE_URL);

  // Validate auth options: exactly one of auth or accessToken must be provided
  if (auth && accessToken) {
    throw new FizzyError("usage", "Provide either 'auth' or 'accessToken', not both");
  }
  if (!auth && !accessToken) {
    throw new FizzyError("usage", "Either 'auth' or 'accessToken' is required");
  }

  const authStrategy: AuthStrategy = auth ?? bearerAuth(accessToken!);

  // Validate HTTPS (skip for localhost)
  if (baseUrl) {
    try {
      const parsed = new URL(baseUrl);
      if (parsed.protocol !== "https:" && !isLocalhost(parsed.hostname)) {
        throw new FizzyError("usage", `Base URL must use HTTPS: ${baseUrl}`);
      }
    } catch (err) {
      if (err instanceof FizzyError) throw err;
      throw new FizzyError("usage", `Invalid base URL: ${baseUrl}`);
    }
  }

  const client = createClient<paths>({ baseUrl });

  // Apply middleware in order: auth first, then hooks, then cache, then retry
  client.use(createAuthMiddleware(authStrategy, userAgent, requestTimeoutMs));

  if (hooks) {
    client.use(createHooksMiddleware(hooks));
  }

  const etagCache = enableCache ? new ETagCache() : undefined;
  if (etagCache) {
    client.use(createCacheMiddleware(etagCache));
  }

  if (enableRetry) {
    client.use(createRetryMiddleware(hooks, authStrategy));
  }

  const enhancedClient = client as FizzyClient;
  Object.defineProperty(enhancedClient, "raw", {
    value: client,
    writable: false,
    enumerable: false,
  });
  Object.defineProperty(enhancedClient, "hooks", {
    value: hooks,
    writable: false,
    enumerable: false,
  });

  // forAccount: creates a new client scoped to a different account
  Object.defineProperty(enhancedClient, "forAccount", {
    value: (newAccountId: string) => {
      return createFizzyClient({
        ...options,
        accountId: newAccountId,
        baseUrl: `${DEFAULT_BASE_URL}/${newAccountId}`,
      });
    },
    writable: false,
    enumerable: false,
  });

  // Authenticated fetchPage closure for pagination
  const fetchPage = async (url: string): Promise<Response> => {
    const headers = new Headers({
      "User-Agent": userAgent,
      Accept: "application/json",
    });
    await authStrategy.authenticate(headers);
    return fetch(url, { headers });
  };

  // Lazy-initialized service cache
  const serviceCache: Record<string, unknown> = {};

  const defineService = <T>(name: string, factory: () => T) => {
    Object.defineProperty(enhancedClient, name, {
      get() {
        return (serviceCache[name] ??= factory()) as T;
      },
      enumerable: true,
      configurable: false,
    });
  };

  // Expose fetchPage and hooks for service internals
  (enhancedClient as unknown as Record<string, unknown>).__fetchPage = fetchPage;
  (enhancedClient as unknown as Record<string, unknown>).__hooks = hooks;

  // Register all generated services as lazy accessors
  registerServices(defineService, enhancedClient, fetchPage, hooks);

  return enhancedClient;
}

// =============================================================================
// Auth Middleware
// =============================================================================

function createAuthMiddleware(authStrategy: AuthStrategy, userAgent: string, requestTimeoutMs: number): Middleware {
  return {
    async onRequest({ request }) {
      await authStrategy.authenticate(request.headers);
      request.headers.set("User-Agent", userAgent);
      if (!request.headers.has("Content-Type")) {
        request.headers.set("Content-Type", "application/json");
      }
      request.headers.set("Accept", "application/json");

      const controller = new AbortController();
      setTimeout(() => controller.abort(), requestTimeoutMs);
      if (request.signal) {
        request.signal.addEventListener("abort", () => controller.abort(), {
          once: true,
        });
      }

      return new Request(request.url, {
        method: request.method,
        headers: request.headers,
        body: request.body,
        signal: controller.signal,
        duplex: request.body ? "half" : undefined,
      } as RequestInit);
    },
  };
}

// =============================================================================
// Hooks Middleware
// =============================================================================

interface RequestTiming {
  startTime: number;
  attempt: number;
}

let requestIdCounter = 0;

function createHooksMiddleware(hooks: FizzyHooks): Middleware {
  const timings = new Map<string, RequestTiming>();

  return {
    async onRequest({ request }) {
      const requestId = `${++requestIdCounter}`;
      request.headers.set("X-SDK-Request-Id", requestId);

      const attemptHeader = request.headers.get("X-Retry-Attempt");
      const attempt = attemptHeader ? parseInt(attemptHeader, 10) + 1 : 1;

      timings.set(requestId, { startTime: performance.now(), attempt });

      const info: RequestInfo = {
        method: request.method,
        url: request.url,
        attempt,
      };

      try { hooks.onRequestStart?.(info); } catch { /* hooks must not interrupt */ }
      return request;
    },

    async onResponse({ request, response }) {
      const requestId = request.headers.get("X-SDK-Request-Id") ?? "";
      const timing = timings.get(requestId);
      const durationMs = timing ? Math.round(performance.now() - timing.startTime) : 0;
      const attempt = timing?.attempt ?? 1;

      timings.delete(requestId);

      const info: RequestInfo = {
        method: request.method,
        url: request.url,
        attempt,
      };

      const fromCacheHeader = response.headers.get("X-From-Cache");
      const fromCache = fromCacheHeader === "1" || response.status === 304;

      const result: RequestResult = {
        statusCode: response.status,
        durationMs,
        fromCache,
      };

      try { hooks.onRequestEnd?.(info, result); } catch { /* hooks must not interrupt */ }
      return response;
    },
  };
}

// =============================================================================
// Cache Middleware (ETag-based)
// =============================================================================

function createCacheMiddleware(cache: ETagCache): Middleware {
  const cacheKeyStore = new WeakMap<Request, string>();

  return {
    async onRequest({ request }) {
      if (request.method !== "GET") return request;

      const cacheKey = await cache.getCacheKey(
        request.url,
        request.headers.get("Authorization") ?? request.headers.get("Cookie"),
      );
      const etag = cache.getETag(cacheKey);

      if (etag) {
        request.headers.set("If-None-Match", etag);
      }

      cacheKeyStore.set(request, cacheKey);
      return request;
    },

    async onResponse({ request, response }) {
      if (request.method !== "GET") return response;

      const cacheKey =
        cacheKeyStore.get(request) ??
        await cache.getCacheKey(
          request.url,
          request.headers.get("Authorization") ?? request.headers.get("Cookie"),
        );

      if (response.status === 304) {
        const body = cache.getBody(cacheKey);
        if (body) {
          const headers = new Headers(response.headers);
          headers.set("X-From-Cache", "1");
          return new Response(body, { status: 200, headers });
        }
      }

      if (response.ok) {
        const etag = response.headers.get("ETag");
        if (etag) {
          const body = await response.clone().text();
          cache.set(cacheKey, etag, body);
        }
      }

      return response;
    },
  };
}

// =============================================================================
// Retry Middleware
// =============================================================================

interface OperationMetadata {
  operations: Record<string, {
    retry?: RetryConfig;
    idempotent?: { natural: boolean };
  }>;
}

interface RetryConfig {
  maxAttempts: number;
  baseDelayMs: number;
  backoff: "exponential" | "linear" | "constant";
  retryOn: number[];
}

const DEFAULT_RETRY_CONFIG: RetryConfig = {
  maxAttempts: 3,
  baseDelayMs: 1000,
  backoff: "exponential",
  retryOn: [429, 503],
};

const MAX_JITTER_MS = 100;

/**
 * Normalizes a URL path by replacing numeric IDs with placeholder tokens.
 * For example: /boards/456/cards/789 -> /boards/{boardId}/cards/{cardNumber}
 */
export function normalizeUrlPath(url: string): string {
  const urlObj = new URL(url);
  let path = urlObj.pathname;

  const hasJsonSuffix = path.endsWith(".json");
  if (hasJsonSuffix) {
    path = path.slice(0, -5);
  }

  const segments = path.split("/").filter(Boolean);

  const idMapping: Record<string, string> = {
    boards: "{boardId}",
    columns: "{columnId}",
    cards: "{cardNumber}",
    comments: "{commentId}",
    steps: "{stepId}",
    reactions: "{reactionId}",
    notifications: "{notificationId}",
    tags: "{tagId}",
    users: "{userId}",
    pins: "{pinId}",
    webhooks: "{webhookId}",
    sessions: "{sessionId}",
    devices: "{deviceId}",
  };

  const normalized: string[] = [];
  let prevSegment: string | null = null;
  let isFirstSegment = true;

  for (let i = 0; i < segments.length; i++) {
    const segment = segments[i]!;

    if (/^\d+$/.test(segment)) {
      if (isFirstSegment) {
        normalized.push("{accountId}");
      } else {
        const placeholder = prevSegment ? idMapping[prevSegment] : undefined;
        normalized.push(placeholder ?? "{id}");
      }
    } else {
      normalized.push(segment);
    }
    prevSegment = segment;
    isFirstSegment = false;
  }

  let normalizedPath = "/" + normalized.join("/");
  if (hasJsonSuffix) {
    normalizedPath += ".json";
  }

  return normalizedPath;
}

function getRetryConfigForRequest(method: string, url: string): RetryConfig {
  const normalizedPath = normalizeUrlPath(url);
  const key = `${method.toUpperCase()}:${normalizedPath}`;
  const operationName = PATH_TO_OPERATION[key];

  if (operationName) {
    const opMeta = metadata.operations[operationName as keyof typeof metadata.operations];
    if (opMeta?.retry) {
      return { ...DEFAULT_RETRY_CONFIG, ...opMeta.retry } as RetryConfig;
    }
  }

  return DEFAULT_RETRY_CONFIG;
}

function createRetryMiddleware(hooks?: FizzyHooks, authStrategy?: AuthStrategy): Middleware {
  const bodyCache = new Map<string, ArrayBuffer | null>();

  return {
    async onRequest({ request }) {
      const method = request.method.toUpperCase();
      if (method === "POST" || method === "PUT" || method === "PATCH") {
        const requestId = `${method}:${request.url}:${Date.now()}`;
        request.headers.set("X-Request-Id", requestId);

        if (request.body) {
          const cloned = request.clone();
          bodyCache.set(requestId, await cloned.arrayBuffer());
        } else {
          bodyCache.set(requestId, null);
        }
      }

      return request;
    },

    async onResponse({ request, response }) {
      const retryConfig = getRetryConfigForRequest(request.method, request.url);
      const requestId = request.headers.get("X-Request-Id");
      const cleanupBody = () => { if (requestId) bodyCache.delete(requestId); };

      let currentResponse = response;
      let attempt = parseInt(request.headers.get("X-Retry-Attempt") || "0", 10);
      if (Number.isNaN(attempt)) attempt = 0;

      try {
        while (retryConfig.retryOn.includes(currentResponse.status) &&
               attempt < retryConfig.maxAttempts - 1) {
          // Calculate delay (Retry-After for 429, backoff otherwise)
          let delay: number;
          if (currentResponse.status === 429) {
            const ra = currentResponse.headers.get("Retry-After");
            const sec = ra ? parseInt(ra, 10) : NaN;
            delay = isNaN(sec) ? calculateBackoffDelay(retryConfig, attempt) : sec * 1000;
          } else {
            delay = calculateBackoffDelay(retryConfig, attempt);
          }

          // Fire hook
          if (hooks?.onRetry) {
            const info: RequestInfo = {
              method: request.method,
              url: request.url,
              attempt: attempt + 1,
            };
            try {
              hooks.onRetry(info, attempt + 1,
                new Error(`HTTP ${currentResponse.status}: ${currentResponse.statusText || "Request failed"}`), delay);
            } catch { /* hooks must not interrupt */ }
          }

          await sleep(delay);
          attempt++;

          // Build retry request
          let body: ArrayBuffer | null = null;
          if (requestId && bodyCache.has(requestId)) {
            body = bodyCache.get(requestId) ?? null;
          }
          const retryHeaders = new Headers(request.headers);
          retryHeaders.set("X-Retry-Attempt", String(attempt));

          if (authStrategy) {
            await authStrategy.authenticate(retryHeaders);
          }

          currentResponse = await fetch(new Request(request.url, {
            method: request.method,
            headers: retryHeaders,
            body,
            signal: request.signal,
          }));
        }

        return currentResponse;
      } finally {
        cleanupBody();
      }
    },
  };
}

function calculateBackoffDelay(config: RetryConfig, attempt: number): number {
  const base = config.baseDelayMs;
  let delay: number;

  switch (config.backoff) {
    case "exponential":
      delay = base * Math.pow(2, attempt);
      break;
    case "linear":
      delay = base * (attempt + 1);
      break;
    case "constant":
    default:
      delay = base;
  }

  const jitter = Math.random() * MAX_JITTER_MS;
  return delay + jitter;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// =============================================================================
// Pagination Helpers
// =============================================================================

/**
 * Fetches all pages of a paginated resource using Link header pagination.
 */
export async function fetchAllPages<T>(
  initialResponse: Response,
  parse: (response: Response) => Promise<T[]>,
  authHeader?: string
): Promise<T[]> {
  const results: T[] = [];
  let response = initialResponse;

  while (true) {
    const items = await parse(response.clone());
    results.push(...items);

    const rawNextUrl = parseNextLink(response.headers.get("Link"));
    if (!rawNextUrl) break;

    const nextUrl = resolveURL(response.url, rawNextUrl);

    if (!isSameOrigin(nextUrl, initialResponse.url)) {
      throw new Error(`Pagination Link header points to different origin: ${nextUrl}`);
    }

    const headers: Record<string, string> = { Accept: "application/json" };
    if (authHeader) {
      headers["Authorization"] = authHeader;
    }

    response = await fetch(nextUrl, { headers });
  }

  return results;
}

/**
 * Async generator that yields pages of results one at a time.
 */
export async function* paginateAll<T>(
  initialResponse: Response,
  parse: (response: Response) => Promise<T[]>,
  authHeader?: string
): AsyncGenerator<T[], void, unknown> {
  let response = initialResponse;

  while (true) {
    const items = await parse(response.clone());
    yield items;

    const rawNextUrl = parseNextLink(response.headers.get("Link"));
    if (!rawNextUrl) break;

    const nextUrl = resolveURL(response.url, rawNextUrl);

    if (!isSameOrigin(nextUrl, initialResponse.url)) {
      throw new Error(`Pagination Link header points to different origin: ${nextUrl}`);
    }

    const headers: Record<string, string> = { Accept: "application/json" };
    if (authHeader) {
      headers["Authorization"] = authHeader;
    }

    response = await fetch(nextUrl, { headers });
  }
}

// Re-export pagination utilities
export { parseNextLink, resolveURL, isSameOrigin };

// =============================================================================
// Service Registration
// =============================================================================

function registerServices(
  defineService: <T>(name: string, factory: () => T) => void,
  client: RawClient,
  fetchPage: (url: string) => Promise<Response>,
  hooks?: FizzyHooks,
) {
  defineService("boards", () => new BoardsService(client, hooks, fetchPage));
  defineService("cards", () => new CardsService(client, hooks, fetchPage));
  defineService("columns", () => new ColumnsService(client, hooks, fetchPage));
  defineService("comments", () => new CommentsService(client, hooks, fetchPage));
  defineService("devices", () => new DevicesService(client, hooks, fetchPage));
  defineService("identity", () => new IdentityService(client, hooks, fetchPage));
  defineService("notifications", () => new NotificationsService(client, hooks, fetchPage));
  defineService("pins", () => new PinsService(client, hooks, fetchPage));
  defineService("reactions", () => new ReactionsService(client, hooks, fetchPage));
  defineService("sessions", () => new SessionsService(client, hooks, fetchPage));
  defineService("steps", () => new StepsService(client, hooks, fetchPage));
  defineService("tags", () => new TagsService(client, hooks, fetchPage));
  defineService("uploads", () => new UploadsService(client, hooks, fetchPage));
  defineService("users", () => new UsersService(client, hooks, fetchPage));
  defineService("webhooks", () => new WebhooksService(client, hooks, fetchPage));
}
