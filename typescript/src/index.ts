/**
 * Fizzy TypeScript SDK
 *
 * Type-safe client for the Fizzy API.
 *
 * @example
 * ```ts
 * import { createFizzyClient } from "@basecamp/fizzy-sdk";
 *
 * const client = createFizzyClient({
 *   accessToken: process.env.FIZZY_TOKEN!,
 * });
 *
 * // High-level service methods
 * const boards = await client.boards.list();
 * const card = await client.cards.create(boardId, {
 *   title: "Ship the feature",
 * });
 *
 * // Or use low-level typed API calls
 * const { data, error } = await client.GET("/boards.json");
 *
 * if (data) {
 *   console.log(data.map(b => b.name));
 * }
 * ```
 *
 * @packageDocumentation
 */

// Main client factory
export {
  createFizzyClient,
  VERSION,
  API_VERSION,
  type FizzyClient,
  type FizzyClientOptions,
  type TokenProvider,
  type RawClient,
} from "./client.js";

// Authentication strategies
export { type AuthStrategy, BearerAuth, bearerAuth } from "./auth-strategy.js";
export { CookieAuth, cookieAuth, type CookieProvider } from "./auth/cookie-auth.js";
export { MagicLinkFlow, type MagicLinkFlowOptions, type MagicLinkRequestResult, type MagicLinkRedeemResult } from "./auth/magic-link.js";

// Pagination helpers
export { fetchAllPages, paginateAll } from "./client.js";

// Pagination types and utilities
export { ListResult, type ListMeta, type PaginationOptions } from "./pagination.js";
export { parseNextLink, resolveURL, isSameOrigin } from "./pagination-utils.js";

// Errors
export {
  FizzyError,
  Errors,
  errorFromResponse,
  isFizzyError,
  isErrorCode,
  type ErrorCode,
  type FizzyErrorOptions,
} from "./errors.js";

// Hooks
export {
  chainHooks,
  consoleHooks,
  noopHooks,
  safeInvoke,
  type FizzyHooks,
  type OperationInfo,
  type RequestInfo,
  type RequestResult,
  type OperationResult,
  type ConsoleHooksOptions,
} from "./hooks.js";

// =============================================================================
// Services - Generated from OpenAPI spec (spec-driven)
// =============================================================================

// Base service (for extending)
export { BaseService, type FetchResponse } from "./services/base.js";

// Identity service
export {
  IdentityService,
  type Identity,
} from "./generated/services/identity.js";

// Core services
export {
  BoardsService,
  type Board,
  type CreateBoardRequest,
  type UpdateBoardRequest,
} from "./generated/services/boards.js";

export {
  ColumnsService,
  type Column,
  type CreateColumnRequest,
  type UpdateColumnRequest,
} from "./generated/services/columns.js";

export {
  CardsService,
  type Card,
  type CreateCardRequest,
  type UpdateCardRequest,
  type MoveCardRequest,
  type AssignCardRequest,
  type TagCardRequest,
} from "./generated/services/cards.js";

export {
  CommentsService,
  type Comment,
  type CreateCommentRequest,
  type UpdateCommentRequest,
} from "./generated/services/comments.js";

export {
  StepsService,
  type Step,
  type CreateStepRequest,
  type UpdateStepRequest,
} from "./generated/services/steps.js";

export {
  ReactionsService,
  type Reaction,
  type CreateReactionRequest,
} from "./generated/services/reactions.js";

export {
  NotificationsService,
  type Notification,
  type NotificationTray,
} from "./generated/services/notifications.js";

export {
  TagsService,
  type Tag,
} from "./generated/services/tags.js";

export {
  UsersService,
  type User,
  type UpdateUserRequest,
} from "./generated/services/users.js";

export {
  PinsService,
  type Pin,
} from "./generated/services/pins.js";

export {
  UploadsService,
  type DirectUpload,
  type CreateDirectUploadRequest,
} from "./generated/services/uploads.js";

// Webhooks management service
export {
  WebhooksService,
  type Webhook,
  type CreateWebhookRequest,
  type UpdateWebhookRequest,
} from "./generated/services/webhooks.js";

// Sessions service
export {
  SessionsService,
  type Session,
  type CreateSessionRequest,
  type RedeemMagicLinkRequest,
  type CompleteSignupRequest,
} from "./generated/services/sessions.js";

// Devices service
export {
  DevicesService,
  type Device,
  type RegisterDeviceRequest,
} from "./generated/services/devices.js";

// =============================================================================
// Webhook Receiving Infrastructure (hand-written, framework-agnostic)
// =============================================================================

export {
  WebhookReceiver,
  WebhookVerificationError,
  type WebhookEvent,
  type WebhookEventHandler,
  type WebhookMiddleware,
  type WebhookReceiverOptions,
  type HeaderAccessor,
} from "./webhooks/handler.js";
export { verifyWebhookSignature, signWebhookPayload } from "./webhooks/verify.js";

// =============================================================================
// Cache
// =============================================================================

export { ETagCache, type ETagCacheOptions } from "./cache/etag-cache.js";

// =============================================================================
// Resilience
// =============================================================================

export {
  CircuitBreaker,
  type CircuitBreakerOptions,
  Bulkhead,
  type BulkheadOptions,
  RateLimiter,
  type RateLimiterOptions,
  type ResilienceConfig,
  createResilienceComponents,
  resilienceHooks,
} from "./resilience/index.js";

// =============================================================================
// Gating hooks (circuit breaker, rate limiter integration)
// =============================================================================

export {
  gatingHooks,
  type GatingHooks,
} from "./hooks/gating.js";

// =============================================================================
// OpenTelemetry hooks
// =============================================================================

export {
  otelHooks,
  type OtelHooksOptions,
} from "./hooks/otel.js";

// =============================================================================
// Security Utilities
// =============================================================================

export {
  redactHeaders,
  redactHeadersRecord,
} from "./security.js";

// Re-export generated types
export type { paths } from "./generated/schema.js";
