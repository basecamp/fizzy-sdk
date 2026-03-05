import Foundation

/// A circuit breaker that prevents cascading failures by stopping requests
/// when the error rate exceeds a threshold.
///
/// States:
/// - **closed**: Requests flow normally; failures are counted.
/// - **open**: All requests are immediately rejected.
/// - **halfOpen**: A limited number of probe requests are allowed through.
public final class CircuitBreaker: @unchecked Sendable {
    private let config: CircuitBreakerConfig
    private let lock = NSLock()

    nonisolated(unsafe) private var state: State = .closed
    nonisolated(unsafe) private var failureCount: Int = 0
    nonisolated(unsafe) private var successCount: Int = 0
    nonisolated(unsafe) private var lastFailureTime: Date?

    /// Current circuit state.
    public enum State: Sendable {
        case closed
        case open
        case halfOpen
    }

    public init(config: CircuitBreakerConfig = CircuitBreakerConfig()) {
        self.config = config
    }

    /// Returns the current state of the circuit breaker.
    public var currentState: State {
        lock.withLock { effectiveState() }
    }

    /// Checks if the request should be allowed through.
    ///
    /// - Returns: `true` if the request is permitted.
    public func allowRequest() -> Bool {
        lock.withLock {
            switch effectiveState() {
            case .closed:
                return true
            case .open:
                return false
            case .halfOpen:
                return true
            }
        }
    }

    /// Records a successful request.
    public func recordSuccess() {
        lock.withLock {
            switch effectiveState() {
            case .halfOpen:
                successCount += 1
                if successCount >= config.successThreshold {
                    reset()
                }
            case .closed:
                failureCount = 0
            case .open:
                break
            }
        }
    }

    /// Records a failed request.
    public func recordFailure() {
        lock.withLock {
            failureCount += 1
            lastFailureTime = Date()
            if failureCount >= config.failureThreshold {
                state = .open
            }
        }
    }

    /// Resets the circuit breaker to closed state.
    public func reset() {
        lock.withLock {
            state = .closed
            failureCount = 0
            successCount = 0
            lastFailureTime = nil
        }
    }

    // MARK: - Private

    private func effectiveState() -> State {
        switch state {
        case .open:
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) >= config.resetTimeout {
                state = .halfOpen
                successCount = 0
                return .halfOpen
            }
            return .open
        default:
            return state
        }
    }
}
