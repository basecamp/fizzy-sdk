/**
 * Gating hooks — extend standard hooks with a pre-flight gate that can
 * reject operations before they execute (e.g., circuit breaker, rate limiter).
 */

import type { FizzyHooks, OperationInfo, RequestInfo, RequestResult, OperationResult } from "../hooks.js";
import { FizzyError } from "../errors.js";

/**
 * Extended hooks interface that adds a gating check before operations.
 */
export interface GatingHooks extends FizzyHooks {
  /**
   * Called before an operation is attempted. Throw to reject the operation.
   * Use this for circuit breakers, rate limiters, bulkheads, etc.
   */
  onOperationGate?(info: OperationInfo): void;
}

/**
 * Creates gating hooks from a gate function and optional inner hooks.
 *
 * @example
 * ```ts
 * const hooks = gatingHooks({
 *   gate: (info) => {
 *     if (circuitBreaker.isOpen(info.service)) {
 *       throw new FizzyError("network", "Circuit breaker is open");
 *     }
 *   },
 *   inner: consoleHooks(),
 * });
 * ```
 */
export function gatingHooks(options: {
  gate: (info: OperationInfo) => void;
  inner?: FizzyHooks;
}): GatingHooks {
  const { gate, inner } = options;

  return {
    onOperationGate(info: OperationInfo) {
      gate(info);
    },

    onOperationStart(info: OperationInfo) {
      try { inner?.onOperationStart?.(info); } catch { /* hooks must not interrupt */ }
    },

    onOperationEnd(info: OperationInfo, result: OperationResult) {
      try { inner?.onOperationEnd?.(info, result); } catch { /* hooks must not interrupt */ }
    },

    onRequestStart(info: RequestInfo) {
      try { inner?.onRequestStart?.(info); } catch { /* hooks must not interrupt */ }
    },

    onRequestEnd(info: RequestInfo, result: RequestResult) {
      try { inner?.onRequestEnd?.(info, result); } catch { /* hooks must not interrupt */ }
    },

    onRetry(info: RequestInfo, attempt: number, error: Error, delayMs: number) {
      try { inner?.onRetry?.(info, attempt, error, delayMs); } catch { /* hooks must not interrupt */ }
    },
  };
}
