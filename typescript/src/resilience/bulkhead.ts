/**
 * Bulkhead (concurrency limiter) for the Fizzy SDK.
 *
 * Limits the number of concurrent in-flight requests to prevent
 * resource exhaustion and provide backpressure.
 */

import { FizzyError } from "../errors.js";

export interface BulkheadOptions {
  /** Maximum concurrent executions (default: 10) */
  maxConcurrent?: number;
  /** Maximum queue size for waiting requests (default: 100, 0 = no queue) */
  maxQueue?: number;
}

interface QueueEntry {
  resolve: () => void;
  reject: (err: Error) => void;
}

/**
 * Concurrency limiter that queues excess requests.
 */
export class Bulkhead {
  private active = 0;
  private readonly queue: QueueEntry[] = [];
  private readonly maxConcurrent: number;
  private readonly maxQueue: number;

  constructor(options?: BulkheadOptions) {
    this.maxConcurrent = options?.maxConcurrent ?? 10;
    this.maxQueue = options?.maxQueue ?? 100;
  }

  /** Number of currently active executions. */
  get activeCount(): number {
    return this.active;
  }

  /** Number of requests waiting in the queue. */
  get queueLength(): number {
    return this.queue.length;
  }

  /**
   * Execute a function with concurrency limiting.
   * If at capacity, queues the request. If the queue is full, rejects immediately.
   */
  async execute<T>(fn: () => Promise<T>): Promise<T> {
    await this.acquire();
    try {
      return await fn();
    } finally {
      this.release();
    }
  }

  private acquire(): Promise<void> {
    if (this.active < this.maxConcurrent) {
      this.active++;
      return Promise.resolve();
    }

    if (this.queue.length >= this.maxQueue) {
      return Promise.reject(
        new FizzyError("api_error", "Bulkhead queue full — too many concurrent requests", {
          hint: "Reduce concurrency or increase bulkhead limits",
        })
      );
    }

    return new Promise<void>((resolve, reject) => {
      this.queue.push({ resolve, reject });
    });
  }

  private release(): void {
    const next = this.queue.shift();
    if (next) {
      next.resolve();
    } else {
      this.active--;
    }
  }
}
