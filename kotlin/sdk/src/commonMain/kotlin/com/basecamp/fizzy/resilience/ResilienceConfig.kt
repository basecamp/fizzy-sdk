package com.basecamp.fizzy.resilience

import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * Configuration for all resilience components.
 *
 * Provides sensible defaults for circuit breaker, bulkhead, and rate limiter.
 * Override individual settings via the builder DSL.
 */
data class ResilienceConfig(
    val circuitBreaker: CircuitBreakerConfig = CircuitBreakerConfig(),
    val bulkhead: BulkheadConfig = BulkheadConfig(),
    val rateLimiter: RateLimiterConfig = RateLimiterConfig(),
)

data class CircuitBreakerConfig(
    /** Number of failures before opening the circuit. */
    val failureThreshold: Int = 5,
    /** Duration the circuit stays open before transitioning to half-open. */
    val resetTimeout: Duration = 30.seconds,
    /** Number of successful calls in half-open to close the circuit. */
    val halfOpenSuccessThreshold: Int = 2,
    /** Status codes considered failures. */
    val failureStatusCodes: Set<Int> = setOf(500, 502, 503, 504),
)

data class BulkheadConfig(
    /** Maximum concurrent requests. */
    val maxConcurrent: Int = 25,
    /** Maximum queue depth when at capacity. */
    val maxQueue: Int = 50,
    /** How long a queued request waits before timing out. */
    val queueTimeout: Duration = 10.seconds,
)

data class RateLimiterConfig(
    /** Maximum requests per window. */
    val maxRequests: Int = 50,
    /** Time window for the rate limit. */
    val window: Duration = 1.seconds,
    /** Minimum time between consecutive requests. */
    val minInterval: Duration = 20.milliseconds,
)
