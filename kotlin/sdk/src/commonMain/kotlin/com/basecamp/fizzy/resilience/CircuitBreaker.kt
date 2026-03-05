package com.basecamp.fizzy.resilience

import com.basecamp.fizzy.FizzyException
import com.basecamp.fizzy.http.currentTimeMillis
import kotlin.time.Duration.Companion.milliseconds

/**
 * Circuit breaker for protecting against cascading failures.
 *
 * States:
 * - **Closed**: Requests flow normally. Failures are counted.
 * - **Open**: Requests are rejected immediately. After [CircuitBreakerConfig.resetTimeout],
 *   transitions to half-open.
 * - **Half-Open**: A limited number of requests are allowed. If they succeed,
 *   the circuit closes. If they fail, it opens again.
 */
class CircuitBreaker(private val config: CircuitBreakerConfig = CircuitBreakerConfig()) {

    enum class State { CLOSED, OPEN, HALF_OPEN }

    @Volatile
    var state: State = State.CLOSED
        private set

    @Volatile
    private var failureCount: Int = 0

    @Volatile
    private var halfOpenSuccessCount: Int = 0

    @Volatile
    private var lastFailureTime: Long = 0

    /**
     * Execute a block with circuit breaker protection.
     *
     * @throws FizzyException.Api if the circuit is open.
     */
    suspend fun <T> execute(block: suspend () -> T): T {
        checkState()

        return try {
            val result = block()
            onSuccess()
            result
        } catch (e: Exception) {
            onFailure()
            throw e
        }
    }

    /**
     * Record an HTTP status code result.
     */
    fun recordStatus(statusCode: Int) {
        if (statusCode in config.failureStatusCodes) {
            onFailure()
        } else {
            onSuccess()
        }
    }

    @Synchronized
    private fun checkState() {
        when (state) {
            State.OPEN -> {
                val elapsed = currentTimeMillis() - lastFailureTime
                if (elapsed >= config.resetTimeout.inWholeMilliseconds) {
                    state = State.HALF_OPEN
                    halfOpenSuccessCount = 0
                } else {
                    throw FizzyException.Api(
                        "Circuit breaker is open",
                        httpStatus = 503,
                        hint = "Too many failures. Retry after ${config.resetTimeout - elapsed.milliseconds}",
                        retryable = true,
                    )
                }
            }
            State.HALF_OPEN, State.CLOSED -> { /* allow request */ }
        }
    }

    @Synchronized
    private fun onSuccess() {
        when (state) {
            State.HALF_OPEN -> {
                halfOpenSuccessCount++
                if (halfOpenSuccessCount >= config.halfOpenSuccessThreshold) {
                    state = State.CLOSED
                    failureCount = 0
                }
            }
            State.CLOSED -> failureCount = 0
            State.OPEN -> { /* shouldn't happen */ }
        }
    }

    @Synchronized
    private fun onFailure() {
        lastFailureTime = currentTimeMillis()
        when (state) {
            State.HALF_OPEN -> {
                state = State.OPEN
            }
            State.CLOSED -> {
                failureCount++
                if (failureCount >= config.failureThreshold) {
                    state = State.OPEN
                }
            }
            State.OPEN -> { /* already open */ }
        }
    }

    /** Reset the circuit breaker to closed state. */
    @Synchronized
    fun reset() {
        state = State.CLOSED
        failureCount = 0
        halfOpenSuccessCount = 0
        lastFailureTime = 0
    }
}

