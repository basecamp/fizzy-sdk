/**
 * In-memory ETag cache for the Fizzy SDK.
 *
 * Provides HTTP conditional request support using ETag/If-None-Match headers.
 * Entries are isolated by auth token hash to prevent cache poisoning across
 * different auth contexts.
 */

interface CacheEntry {
  etag: string;
  body: string;
}

export interface ETagCacheOptions {
  /** Maximum number of cached responses (default: 1000) */
  maxEntries?: number;
  /** Maximum number of token hash entries (default: 100) */
  maxTokenHashes?: number;
}

/**
 * In-memory ETag cache with token-hash isolation.
 * Uses Map insertion-order iteration to approximate LRU eviction.
 */
export class ETagCache {
  private readonly cache = new Map<string, CacheEntry>();
  private readonly maxEntries: number;
  private readonly maxTokenHashes: number;
  private readonly hashTokenMap = new Map<string, string>();
  private readonly pendingHashes = new Map<string, Promise<string>>();

  constructor(options?: ETagCacheOptions) {
    this.maxEntries = options?.maxEntries ?? 1000;
    this.maxTokenHashes = options?.maxTokenHashes ?? 100;
  }

  /**
   * Get the stored ETag for a URL (if any).
   */
  getETag(cacheKey: string): string | undefined {
    return this.cache.get(cacheKey)?.etag;
  }

  /**
   * Get the stored response body for a URL (if any).
   */
  getBody(cacheKey: string): string | undefined {
    return this.cache.get(cacheKey)?.body;
  }

  /**
   * Store an ETag and response body.
   */
  set(cacheKey: string, etag: string, body: string): void {
    this.evictOldest();
    this.cache.set(cacheKey, { etag, body });
  }

  /**
   * Derive a cache key from URL and auth header.
   */
  async getCacheKey(url: string, authHeader: string | null): Promise<string> {
    const tokenHash = await this.getTokenHash(authHeader);
    return `${tokenHash}:${url}`;
  }

  /** Number of cached entries. */
  get size(): number {
    return this.cache.size;
  }

  /** Clear all cached entries. */
  clear(): void {
    this.cache.clear();
  }

  private async getTokenHash(authHeader: string | null): Promise<string> {
    if (!authHeader) return "";

    const cached = this.hashTokenMap.get(authHeader);
    if (cached) return cached;

    const pending = this.pendingHashes.get(authHeader);
    if (pending) return pending;

    const promise = (async () => {
      const data = new TextEncoder().encode(authHeader);
      const hashBuffer = await crypto.subtle.digest("SHA-256", data);
      const hashArray = new Uint8Array(hashBuffer);
      const hash = Array.from(hashArray.slice(0, 8))
        .map((b) => b.toString(16).padStart(2, "0"))
        .join("");
      this.evictOldestHash();
      this.hashTokenMap.set(authHeader, hash);
      return hash;
    })();

    this.pendingHashes.set(authHeader, promise);
    promise.finally(() => this.pendingHashes.delete(authHeader));

    return promise;
  }

  private evictOldest(): void {
    if (this.cache.size >= this.maxEntries) {
      const firstKey = this.cache.keys().next().value;
      if (firstKey) this.cache.delete(firstKey);
    }
  }

  private evictOldestHash(): void {
    if (this.hashTokenMap.size >= this.maxTokenHashes) {
      const firstKey = this.hashTokenMap.keys().next().value;
      if (firstKey) this.hashTokenMap.delete(firstKey);
    }
  }
}
