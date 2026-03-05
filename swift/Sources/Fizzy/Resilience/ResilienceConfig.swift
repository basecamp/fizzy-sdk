import Foundation

/// Configuration for the resilience layer.
///
/// Controls circuit breaker, bulkhead, and rate limiter behavior.
/// All values have sensible defaults.
public struct ResilienceConfig: Sendable {
    /// Circuit breaker configuration.
    public let circuitBreaker: CircuitBreakerConfig

    /// Bulkhead configuration.
    public let bulkhead: BulkheadConfig

    /// Rate limiter configuration.
    public let rateLimiter: RateLimiterConfig

    public init(
        circuitBreaker: CircuitBreakerConfig = CircuitBreakerConfig(),
        bulkhead: BulkheadConfig = BulkheadConfig(),
        rateLimiter: RateLimiterConfig = RateLimiterConfig()
    ) {
        self.circuitBreaker = circuitBreaker
        self.bulkhead = bulkhead
        self.rateLimiter = rateLimiter
    }

    /// Default resilience configuration.
    public static let `default` = ResilienceConfig()
}

/// Circuit breaker configuration.
public struct CircuitBreakerConfig: Sendable {
    /// Number of consecutive failures before opening the circuit.
    public let failureThreshold: Int
    /// Duration the circuit stays open before entering half-open state.
    public let resetTimeout: TimeInterval
    /// Number of successful probes in half-open state before closing.
    public let successThreshold: Int

    public init(failureThreshold: Int = 5, resetTimeout: TimeInterval = 30, successThreshold: Int = 2) {
        self.failureThreshold = failureThreshold
        self.resetTimeout = resetTimeout
        self.successThreshold = successThreshold
    }
}

/// Bulkhead configuration.
public struct BulkheadConfig: Sendable {
    /// Maximum number of concurrent requests.
    public let maxConcurrent: Int

    public init(maxConcurrent: Int = 10) {
        self.maxConcurrent = maxConcurrent
    }
}

/// Rate limiter configuration.
public struct RateLimiterConfig: Sendable {
    /// Maximum number of requests per window.
    public let maxRequests: Int
    /// Window duration in seconds.
    public let windowSeconds: TimeInterval

    public init(maxRequests: Int = 50, windowSeconds: TimeInterval = 10) {
        self.maxRequests = maxRequests
        self.windowSeconds = windowSeconds
    }
}
