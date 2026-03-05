package com.basecamp.fizzy.http

/**
 * In-memory ETag cache for conditional HTTP requests.
 *
 * Stores ETag values keyed by URL. When a response includes an ETag header,
 * subsequent requests to the same URL include `If-None-Match`, allowing the
 * server to return 304 Not Modified.
 *
 * Thread-safe via synchronized access.
 */
internal class ETagCache {
    private val entries = mutableMapOf<String, CacheEntry>()

    data class CacheEntry(
        val etag: String,
        val body: String,
    )

    @Synchronized
    fun get(url: String): CacheEntry? = entries[url]

    @Synchronized
    fun put(url: String, etag: String, body: String) {
        entries[url] = CacheEntry(etag, body)
    }

    @Synchronized
    fun remove(url: String) {
        entries.remove(url)
    }

    @Synchronized
    fun clear() {
        entries.clear()
    }

    @Synchronized
    fun size(): Int = entries.size
}
