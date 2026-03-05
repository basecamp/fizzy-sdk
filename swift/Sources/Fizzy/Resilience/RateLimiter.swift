import Foundation

/// A sliding-window rate limiter that tracks request timestamps and
/// rejects requests that exceed the configured rate.
public final class RateLimiter: @unchecked Sendable {
    private let config: RateLimiterConfig
    private let lock = NSLock()
    nonisolated(unsafe) private var timestamps: [Date] = []

    public init(config: RateLimiterConfig = RateLimiterConfig()) {
        self.config = config
    }

    /// Attempts to acquire permission for a new request.
    ///
    /// - Returns: `true` if the request is within rate limits, `false` otherwise.
    public func tryAcquire() -> Bool {
        lock.withLock {
            pruneExpired()
            if timestamps.count < config.maxRequests {
                timestamps.append(Date())
                return true
            }
            return false
        }
    }

    /// Returns the number of requests remaining in the current window.
    public var remaining: Int {
        lock.withLock {
            pruneExpired()
            return max(0, config.maxRequests - timestamps.count)
        }
    }

    /// Resets all tracked timestamps.
    public func reset() {
        lock.withLock {
            timestamps.removeAll()
        }
    }

    // MARK: - Private

    private func pruneExpired() {
        let cutoff = Date().addingTimeInterval(-config.windowSeconds)
        timestamps.removeAll { $0 < cutoff }
    }
}
