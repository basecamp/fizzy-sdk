import Foundation

/// A bulkhead that limits the number of concurrent requests to prevent
/// resource exhaustion.
///
/// Uses a counting semaphore pattern with `NSLock` for thread safety.
public final class Bulkhead: @unchecked Sendable {
    private let config: BulkheadConfig
    private let lock = NSLock()
    nonisolated(unsafe) private var activeCount: Int = 0

    public init(config: BulkheadConfig = BulkheadConfig()) {
        self.config = config
    }

    /// The current number of active (in-flight) requests.
    public var current: Int {
        lock.withLock { activeCount }
    }

    /// Attempts to acquire a slot for a new request.
    ///
    /// - Returns: `true` if a slot was acquired, `false` if at capacity.
    public func tryAcquire() -> Bool {
        lock.withLock {
            if activeCount < config.maxConcurrent {
                activeCount += 1
                return true
            }
            return false
        }
    }

    /// Releases a previously acquired slot.
    public func release() {
        lock.withLock {
            activeCount = max(0, activeCount - 1)
        }
    }

    /// Executes an async operation within the bulkhead.
    ///
    /// - Parameter operation: The async operation to execute.
    /// - Returns: The result of the operation.
    /// - Throws: `FizzyError.api` if the bulkhead is at capacity.
    public func execute<T: Sendable>(_ operation: @Sendable () async throws -> T) async throws -> T {
        guard tryAcquire() else {
            throw FizzyError.api(
                message: "Bulkhead capacity exceeded (\(config.maxConcurrent) concurrent requests)",
                httpStatus: nil, hint: "Reduce concurrency or increase bulkhead limit", requestId: nil
            )
        }
        defer { release() }
        return try await operation()
    }
}
