/**
 * Token bucket rate limiter for the Fizzy SDK.
 *
 * Smooths request rates to stay within API rate limits.
 * Tokens refill at a constant rate; each request consumes one token.
 */

export interface RateLimiterOptions {
  /** Maximum tokens in the bucket (default: 50) */
  maxTokens?: number;
  /** Token refill rate — tokens per second (default: 10) */
  refillRate?: number;
}

/**
 * Token bucket rate limiter.
 */
export class RateLimiter {
  private tokens: number;
  private readonly maxTokens: number;
  private readonly refillRate: number;
  private lastRefillTime: number;

  constructor(options?: RateLimiterOptions) {
    this.maxTokens = options?.maxTokens ?? 50;
    this.refillRate = options?.refillRate ?? 10;
    this.tokens = this.maxTokens;
    this.lastRefillTime = Date.now();
  }

  /** Current number of available tokens. */
  get availableTokens(): number {
    this.refill();
    return this.tokens;
  }

  /**
   * Try to consume a token. Returns true if a token was available.
   */
  tryAcquire(): boolean {
    this.refill();
    if (this.tokens >= 1) {
      this.tokens--;
      return true;
    }
    return false;
  }

  /**
   * Wait until a token is available, then consume it.
   */
  async acquire(): Promise<void> {
    if (this.tryAcquire()) return;

    const waitMs = this.msUntilNextToken();
    await new Promise((resolve) => setTimeout(resolve, waitMs));

    // Refill and take the token
    this.refill();
    this.tokens = Math.max(0, this.tokens - 1);
  }

  /**
   * Estimated milliseconds until the next token becomes available.
   */
  msUntilNextToken(): number {
    this.refill();
    if (this.tokens >= 1) return 0;
    const deficit = 1 - this.tokens;
    return Math.ceil((deficit / this.refillRate) * 1000);
  }

  private refill(): void {
    const now = Date.now();
    const elapsed = (now - this.lastRefillTime) / 1000;
    const newTokens = elapsed * this.refillRate;

    if (newTokens > 0) {
      this.tokens = Math.min(this.maxTokens, this.tokens + newTokens);
      this.lastRefillTime = now;
    }
  }
}
