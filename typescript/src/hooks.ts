/**
 * Observability hooks system for the Fizzy SDK.
 *
 * Provides a way to observe API operations and HTTP requests
 * without modifying the core client logic.
 */

/**
 * Information about a high-level service operation.
 */
export interface OperationInfo {
  /** Service name (e.g., "Cards", "Boards") */
  service: string;
  /** Operation name (e.g., "List", "Get", "Create") */
  operation: string;
  /** Type of resource being accessed */
  resourceType: string;
  /** Whether this operation modifies data */
  isMutation: boolean;
  /** Board ID if the operation is scoped to a board */
  boardId?: number;
  /** Resource ID if the operation targets a specific resource */
  resourceId?: number;
}

/**
 * Information about an HTTP request.
 */
export interface RequestInfo {
  /** HTTP method */
  method: string;
  /** Full request URL */
  url: string;
  /** Current attempt number (1-based) */
  attempt: number;
}

/**
 * Result of an HTTP request.
 */
export interface RequestResult {
  /** HTTP status code */
  statusCode: number;
  /** Request duration in milliseconds */
  durationMs: number;
  /** Whether the response was served from cache */
  fromCache: boolean;
  /** Error if the request failed */
  error?: Error;
}

/**
 * Result of an operation.
 */
export interface OperationResult {
  /** Error if the operation failed */
  error?: Error;
  /** Operation duration in milliseconds */
  durationMs: number;
}

/**
 * Hooks interface for observing SDK operations.
 * All hooks are optional — implement only what you need.
 */
export interface FizzyHooks {
  /** Called when a service operation starts. */
  onOperationStart?(info: OperationInfo): void;
  /** Called when a service operation completes (success or failure). */
  onOperationEnd?(info: OperationInfo, result: OperationResult): void;
  /** Called when an HTTP request starts (including retries). */
  onRequestStart?(info: RequestInfo): void;
  /** Called when an HTTP request completes (including retries). */
  onRequestEnd?(info: RequestInfo, result: RequestResult): void;
  /** Called before a retry attempt. */
  onRetry?(info: RequestInfo, attempt: number, error: Error, delayMs: number): void;
}

/**
 * Combines multiple hooks into a single hooks object.
 */
export function chainHooks(...hooks: FizzyHooks[]): FizzyHooks {
  const activeHooks = hooks.filter(Boolean);

  if (activeHooks.length === 0) return {};
  if (activeHooks.length === 1) return activeHooks[0]!;

  return {
    onOperationStart: (info) => {
      for (const h of activeHooks) {
        try { h.onOperationStart?.(info); } catch { /* hooks must not interrupt */ }
      }
    },

    onOperationEnd: (info, result) => {
      for (const h of activeHooks) {
        try { h.onOperationEnd?.(info, result); } catch { /* hooks must not interrupt */ }
      }
    },

    onRequestStart: (info) => {
      for (const h of activeHooks) {
        try { h.onRequestStart?.(info); } catch { /* hooks must not interrupt */ }
      }
    },

    onRequestEnd: (info, result) => {
      for (const h of activeHooks) {
        try { h.onRequestEnd?.(info, result); } catch { /* hooks must not interrupt */ }
      }
    },

    onRetry: (info, attempt, error, delayMs) => {
      for (const h of activeHooks) {
        try { h.onRetry?.(info, attempt, error, delayMs); } catch { /* hooks must not interrupt */ }
      }
    },
  };
}

/**
 * Options for console logging hooks.
 */
export interface ConsoleHooksOptions {
  logOperations?: boolean;
  logRequests?: boolean;
  logRetries?: boolean;
  minDurationMs?: number;
  logger?: Pick<Console, "log" | "warn" | "error">;
}

/**
 * Creates hooks that log to the console.
 */
export function consoleHooks(options: ConsoleHooksOptions = {}): FizzyHooks {
  const {
    logOperations = true,
    logRequests = false,
    logRetries = true,
    minDurationMs = 0,
    logger = console,
  } = options;

  return {
    onOperationStart: logOperations
      ? (info) => {
          const mutation = info.isMutation ? " [mutation]" : "";
          const resource = info.resourceId ? ` #${info.resourceId}` : "";
          const board = info.boardId ? ` (board: ${info.boardId})` : "";
          logger.log(`[Fizzy] ${info.service}.${info.operation}${resource}${board}${mutation}`);
        }
      : undefined,

    onOperationEnd: logOperations
      ? (info, result) => {
          if (result.durationMs < minDurationMs) return;
          const duration = `${result.durationMs}ms`;
          if (result.error) {
            logger.error(
              `[Fizzy] ${info.service}.${info.operation} failed (${duration}):`,
              result.error.message
            );
          } else {
            logger.log(`[Fizzy] ${info.service}.${info.operation} completed (${duration})`);
          }
        }
      : undefined,

    onRequestStart: logRequests
      ? (info) => {
          const retry = info.attempt > 1 ? ` (attempt ${info.attempt})` : "";
          logger.log(`[Fizzy] -> ${info.method} ${info.url}${retry}`);
        }
      : undefined,

    onRequestEnd: logRequests
      ? (info, result) => {
          if (result.durationMs < minDurationMs) return;
          const cache = result.fromCache ? " (cached)" : "";
          const status = result.error ? "error" : result.statusCode;
          logger.log(`[Fizzy] <- ${info.method} ${info.url} ${status} (${result.durationMs}ms)${cache}`);
        }
      : undefined,

    onRetry: logRetries
      ? (info, attempt, error, delayMs) => {
          logger.warn(
            `[Fizzy] Retrying ${info.method} ${info.url} (attempt ${attempt + 1}, waiting ${delayMs}ms): ${error.message}`
          );
        }
      : undefined,
  };
}

/**
 * Creates a no-op hooks object.
 */
export function noopHooks(): FizzyHooks {
  return {};
}

/**
 * Internal helper to safely invoke a hook.
 */
export function safeInvoke<K extends keyof FizzyHooks>(
  hooks: FizzyHooks | undefined,
  hookName: K,
  ...args: Parameters<NonNullable<FizzyHooks[K]>>
): void {
  if (!hooks) return;
  const hook = hooks[hookName];
  if (!hook) return;
  try {
    (hook as (...a: unknown[]) => void)(...args);
  } catch (err) {
    console.error(`Hook ${hookName} error:`, err);
  }
}
