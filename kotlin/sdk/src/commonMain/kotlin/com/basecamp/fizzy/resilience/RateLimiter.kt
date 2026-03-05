package com.basecamp.fizzy.resilience

import com.basecamp.fizzy.http.currentTimeMillis
import kotlinx.coroutines.delay
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * Token-bucket rate limiter for outgoing requests.
 *
 * Enforces both a per-window request limit and a minimum interval between
 * consecutive requests. When limits are exceeded, callers are suspended
 * until capacity is available.
 */
class RateLimiter(private val config: RateLimiterConfig = RateLimiterConfig()) {

    private val mutex = Mutex()
    private var windowStart: Long = 0
    private var windowCount: Int = 0
    private var lastRequestTime: Long = 0

    /**
     * Acquire permission to make a request, blocking if necessary.
     */
    suspend fun acquire() {
        mutex.withLock {
            val now = currentTimeMillis()

            // Reset window if expired
            if (now - windowStart >= config.window.inWholeMilliseconds) {
                windowStart = now
                windowCount = 0
            }

            // Wait if window is exhausted
            if (windowCount >= config.maxRequests) {
                val waitMs = config.window.inWholeMilliseconds - (now - windowStart)
                if (waitMs > 0) {
                    delay(waitMs)
                }
                windowStart = currentTimeMillis()
                windowCount = 0
            }

            // Enforce minimum interval
            val timeSinceLast = currentTimeMillis() - lastRequestTime
            val minIntervalMs = config.minInterval.inWholeMilliseconds
            if (timeSinceLast < minIntervalMs) {
                delay(minIntervalMs - timeSinceLast)
            }

            windowCount++
            lastRequestTime = currentTimeMillis()
        }
    }

    /** Reset the rate limiter state. */
    suspend fun reset() {
        mutex.withLock {
            windowStart = 0
            windowCount = 0
            lastRequestTime = 0
        }
    }
}
