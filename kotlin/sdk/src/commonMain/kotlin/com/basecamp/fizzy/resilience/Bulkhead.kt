package com.basecamp.fizzy.resilience

import com.basecamp.fizzy.FizzyException
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit
import kotlinx.coroutines.withTimeout

/**
 * Bulkhead for limiting concurrent requests.
 *
 * Uses a semaphore to cap the number of in-flight requests. Requests exceeding
 * the limit are queued up to [BulkheadConfig.maxQueue] and timeout after
 * [BulkheadConfig.queueTimeout].
 */
class Bulkhead(private val config: BulkheadConfig = BulkheadConfig()) {

    private val semaphore = Semaphore(config.maxConcurrent)

    /** Current number of active (in-flight) requests. */
    val activeCount: Int get() = config.maxConcurrent - semaphore.availablePermits

    /**
     * Execute a block with bulkhead protection.
     *
     * @throws FizzyException.Api if the queue is full or the timeout expires.
     */
    suspend fun <T> execute(block: suspend () -> T): T {
        try {
            return withTimeout(config.queueTimeout) {
                semaphore.withPermit {
                    block()
                }
            }
        } catch (_: TimeoutCancellationException) {
            throw FizzyException.Api(
                "Bulkhead queue timeout exceeded (${config.queueTimeout})",
                httpStatus = 503,
                hint = "Too many concurrent requests. Try again later.",
                retryable = true,
            )
        }
    }
}
