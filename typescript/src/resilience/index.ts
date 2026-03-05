/**
 * Resilience module for the Fizzy SDK.
 *
 * Composes circuit breaker, bulkhead, and rate limiter into a unified
 * configuration and hooks integration.
 */

import { CircuitBreaker, type CircuitBreakerOptions } from "./circuit-breaker.js";
import { Bulkhead, type BulkheadOptions } from "./bulkhead.js";
import { RateLimiter, type RateLimiterOptions } from "./rate-limiter.js";
import type { FizzyHooks, RequestInfo, RequestResult } from "../hooks.js";

export { CircuitBreaker, type CircuitBreakerOptions } from "./circuit-breaker.js";
export { Bulkhead, type BulkheadOptions } from "./bulkhead.js";
export { RateLimiter, type RateLimiterOptions } from "./rate-limiter.js";

/**
 * Unified resilience configuration.
 */
export interface ResilienceConfig {
  /** Circuit breaker options (false to disable) */
  circuitBreaker?: CircuitBreakerOptions | false;
  /** Bulkhead / concurrency limiter options (false to disable) */
  bulkhead?: BulkheadOptions | false;
  /** Rate limiter options (false to disable) */
  rateLimiter?: RateLimiterOptions | false;
}

/**
 * Active resilience components created from configuration.
 */
export interface ResilienceComponents {
  circuitBreaker?: CircuitBreaker;
  bulkhead?: Bulkhead;
  rateLimiter?: RateLimiter;
}

/**
 * Create resilience components from configuration.
 */
export function createResilienceComponents(config: ResilienceConfig): ResilienceComponents {
  return {
    circuitBreaker: config.circuitBreaker !== false
      ? new CircuitBreaker(config.circuitBreaker === undefined ? {} : config.circuitBreaker)
      : undefined,
    bulkhead: config.bulkhead !== false
      ? new Bulkhead(config.bulkhead === undefined ? {} : config.bulkhead)
      : undefined,
    rateLimiter: config.rateLimiter !== false
      ? new RateLimiter(config.rateLimiter === undefined ? {} : config.rateLimiter)
      : undefined,
  };
}

/**
 * Creates FizzyHooks that track circuit breaker state from request results.
 */
export function resilienceHooks(components: ResilienceComponents): FizzyHooks {
  return {
    onRequestEnd(_info: RequestInfo, result: RequestResult): void {
      if (!components.circuitBreaker) return;

      if (result.statusCode >= 500) {
        components.circuitBreaker.recordFailure();
      } else {
        components.circuitBreaker.recordSuccess();
      }
    },
  };
}
