/**
 * Circuit breaker for the Fizzy SDK.
 *
 * Prevents cascading failures by tracking error rates and temporarily
 * stopping requests when the failure threshold is exceeded.
 */

export type CircuitState = "closed" | "open" | "half-open";

export interface CircuitBreakerOptions {
  /** Number of failures before opening the circuit (default: 5) */
  failureThreshold?: number;
  /** Time in ms before attempting to half-open (default: 30000) */
  resetTimeoutMs?: number;
  /** Number of successful requests to close from half-open (default: 1) */
  successThreshold?: number;
}

/**
 * Circuit breaker implementation using the standard closed/open/half-open pattern.
 */
export class CircuitBreaker {
  private state: CircuitState = "closed";
  private failureCount = 0;
  private successCount = 0;
  private lastFailureTime = 0;
  private readonly failureThreshold: number;
  private readonly resetTimeoutMs: number;
  private readonly successThreshold: number;

  constructor(options?: CircuitBreakerOptions) {
    this.failureThreshold = options?.failureThreshold ?? 5;
    this.resetTimeoutMs = options?.resetTimeoutMs ?? 30_000;
    this.successThreshold = options?.successThreshold ?? 1;
  }

  /** Current circuit state. */
  get currentState(): CircuitState {
    if (this.state === "open" && Date.now() - this.lastFailureTime >= this.resetTimeoutMs) {
      this.state = "half-open";
    }
    return this.state;
  }

  /**
   * Check if a request is allowed through the circuit.
   * Returns true if the circuit is closed or half-open.
   */
  allowRequest(): boolean {
    return this.currentState !== "open";
  }

  /**
   * Record a successful request.
   */
  recordSuccess(): void {
    if (this.state === "half-open") {
      this.successCount++;
      if (this.successCount >= this.successThreshold) {
        this.state = "closed";
        this.failureCount = 0;
        this.successCount = 0;
      }
    } else {
      this.failureCount = 0;
    }
  }

  /**
   * Record a failed request.
   */
  recordFailure(): void {
    this.failureCount++;
    this.lastFailureTime = Date.now();

    if (this.state === "half-open" || this.failureCount >= this.failureThreshold) {
      this.state = "open";
      this.successCount = 0;
    }
  }

  /**
   * Reset the circuit breaker to closed state.
   */
  reset(): void {
    this.state = "closed";
    this.failureCount = 0;
    this.successCount = 0;
    this.lastFailureTime = 0;
  }
}
