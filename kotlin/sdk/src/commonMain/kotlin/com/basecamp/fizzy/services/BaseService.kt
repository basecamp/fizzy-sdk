package com.basecamp.fizzy.services

import com.basecamp.fizzy.*
import com.basecamp.fizzy.http.FizzyHttpClient
import com.basecamp.fizzy.http.currentTimeMillis
import com.basecamp.fizzy.http.millisToDuration
import io.ktor.client.statement.*
import io.ktor.http.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive

/**
 * Abstract base class for all Fizzy API services.
 *
 * Provides shared functionality for making API requests, handling errors,
 * and integrating with the hooks system. Generated service classes extend this.
 *
 * ```kotlin
 * class CardsService(client: AccountClient) : BaseService(client) {
 *     suspend fun list(boardId: Long): ListResult<Card> =
 *         requestPaginated(
 *             OperationInfo("Cards", "ListCards", "card", false, boardId),
 *         ) {
 *             httpGet("/boards/$boardId/cards.json")
 *         }
 * }
 * ```
 */
abstract class BaseService(
    private val accountClient: AccountClient,
) {
    private val http: FizzyHttpClient get() = accountClient.httpClient
    private val hooks: FizzyHooks get() = accountClient.parent.hooks
    protected val json: Json get() = http.json

    /** Maximum pages to follow as a safety cap against infinite loops. */
    private val maxPages: Int get() = accountClient.parent.config.maxPages

    /**
     * Builds the full API URL for a path relative to the account.
     * E.g., "/boards.json" -> "https://fizzy.do/{accountId}/boards.json"
     */
    protected fun accountUrl(path: String): String {
        val base = accountClient.parent.config.baseUrl.trimEnd('/')
        val accountId = accountClient.accountId
        val normalizedPath = if (path.startsWith("/")) path else "/$path"
        return "$base/$accountId$normalizedPath"
    }

    /**
     * Builds the full API URL for account-independent paths.
     * E.g., "/session.json" -> "https://fizzy.do/session.json"
     */
    protected fun rootUrl(path: String): String {
        val base = accountClient.parent.config.baseUrl.trimEnd('/')
        val normalizedPath = if (path.startsWith("/")) path else "/$path"
        return "$base$normalizedPath"
    }

    /**
     * Builds a query string from key-value pairs, URL-encoding values.
     * Null values are omitted. Returns "" if no params, or "?k1=v1&k2=v2".
     */
    protected fun buildQueryString(vararg params: Pair<String, Any?>): String {
        val parts = params.mapNotNull { (key, value) ->
            value?.let { "$key=${it.toString().encodeURLParameter()}" }
        }
        return if (parts.isEmpty()) "" else "?" + parts.joinToString("&")
    }

    /**
     * Executes a GET request for the given account-relative path.
     */
    protected suspend fun httpGet(path: String, operationName: String? = null): HttpResponse =
        http.requestWithRetry(HttpMethod.Get, accountUrl(path), operationName = operationName)

    /**
     * Executes a POST request with a JSON body.
     */
    protected suspend fun httpPost(path: String, body: String? = null, operationName: String? = null): HttpResponse =
        http.requestWithRetry(HttpMethod.Post, accountUrl(path), body, operationName = operationName)

    /**
     * Executes a PUT request with a JSON body.
     */
    protected suspend fun httpPut(path: String, body: String? = null, operationName: String? = null): HttpResponse =
        http.requestWithRetry(HttpMethod.Put, accountUrl(path), body, operationName = operationName)

    /**
     * Executes a PATCH request with a JSON body.
     */
    protected suspend fun httpPatch(path: String, body: String? = null, operationName: String? = null): HttpResponse =
        http.requestWithRetry(HttpMethod.Patch, accountUrl(path), body, operationName = operationName)

    /**
     * Executes a DELETE request.
     */
    protected suspend fun httpDelete(path: String, operationName: String? = null): HttpResponse =
        http.requestWithRetry(HttpMethod.Delete, accountUrl(path), operationName = operationName)

    /**
     * Executes a POST request with binary body data.
     */
    protected suspend fun httpPostBinary(path: String, data: ByteArray, contentType: String): HttpResponse =
        http.requestBinaryWithRetry(HttpMethod.Post, accountUrl(path), data, contentType)

    /**
     * Executes a GET request for an account-independent path.
     */
    protected suspend fun httpGetRoot(path: String, operationName: String? = null): HttpResponse =
        http.requestWithRetry(HttpMethod.Get, rootUrl(path), operationName = operationName)

    /**
     * Executes a POST request for an account-independent path.
     */
    protected suspend fun httpPostRoot(path: String, body: String? = null, operationName: String? = null): HttpResponse =
        http.requestWithRetry(HttpMethod.Post, rootUrl(path), body, operationName = operationName)

    /**
     * Executes a PUT request for an account-independent path.
     */
    protected suspend fun httpPutRoot(path: String, body: String? = null, operationName: String? = null): HttpResponse =
        http.requestWithRetry(HttpMethod.Put, rootUrl(path), body, operationName = operationName)

    /**
     * Executes a PATCH request for an account-independent path.
     */
    protected suspend fun httpPatchRoot(path: String, body: String? = null, operationName: String? = null): HttpResponse =
        http.requestWithRetry(HttpMethod.Patch, rootUrl(path), body, operationName = operationName)

    /**
     * Executes a DELETE request for an account-independent path.
     */
    protected suspend fun httpDeleteRoot(path: String, operationName: String? = null): HttpResponse =
        http.requestWithRetry(HttpMethod.Delete, rootUrl(path), operationName = operationName)

    /**
     * Executes an API request with error handling and hooks integration.
     *
     * @param info Operation metadata for hooks.
     * @param fn The suspend function that performs the actual HTTP call.
     * @param parse Deserializes the response body string into the result type.
     * @return The parsed response.
     */
    protected suspend fun <T> request(
        info: OperationInfo,
        fn: suspend () -> HttpResponse,
        parse: (String) -> T,
    ): T {
        val startTime = currentTimeMillis()

        hooks.safeOnOperationStart(info)

        try {
            val response = fn()
            val duration = (currentTimeMillis() - startTime).millisToDuration()

            if (!response.status.isSuccess()) {
                val error = errorFromResponse(response)
                hooks.safeOnOperationEnd(info, OperationResult(duration, error))
                throw error
            }

            // 204 No Content
            if (response.status.value == 204) {
                hooks.safeOnOperationEnd(info, OperationResult(duration))
                @Suppress("UNCHECKED_CAST")
                return Unit as T
            }

            val bodyText = response.bodyAsText()
            val result = parse(bodyText)
            hooks.safeOnOperationEnd(info, OperationResult(duration))
            return result
        } catch (e: FizzyException) {
            val duration = (currentTimeMillis() - startTime).millisToDuration()
            hooks.safeOnOperationEnd(info, OperationResult(duration, e))
            throw e
        } catch (e: Exception) {
            val duration = (currentTimeMillis() - startTime).millisToDuration()
            hooks.safeOnOperationEnd(info, OperationResult(duration, e))
            throw e
        }
    }

    /**
     * Executes a paginated API request, automatically following Link headers.
     *
     * Returns a [ListResult] with all items across pages, plus [ListMeta]
     * with `truncated` information. Fizzy does not return X-Total-Count.
     *
     * @param info Operation metadata for hooks.
     * @param options Pagination control (maxItems).
     * @param fn The suspend function that performs the initial HTTP call.
     * @param parseItems Parses a page's response body into a list of items.
     */
    protected suspend fun <T> requestPaginated(
        info: OperationInfo,
        options: PaginationOptions? = null,
        fn: suspend () -> HttpResponse,
        parseItems: (String) -> List<T>,
    ): ListResult<T> {
        val startTime = currentTimeMillis()
        val maxItems = options?.maxItems

        hooks.safeOnOperationStart(info)

        try {
            val response = fn()

            if (!response.status.isSuccess()) {
                val error = errorFromResponse(response)
                val duration = (currentTimeMillis() - startTime).millisToDuration()
                hooks.safeOnOperationEnd(info, OperationResult(duration, error))
                throw error
            }

            val bodyText = response.bodyAsText()
            val firstPageItems = parseItems(bodyText)

            // Check if maxItems is satisfied by the first page
            if (maxItems != null && maxItems > 0 && firstPageItems.size >= maxItems) {
                val hasMore = firstPageItems.size > maxItems
                    || parseNextLink(response.headers["Link"]) != null
                val duration = (currentTimeMillis() - startTime).millisToDuration()
                val result = ListResult(firstPageItems.take(maxItems), ListMeta(hasMore))
                hooks.safeOnOperationEnd(info, OperationResult(duration))
                return result
            }

            // Follow pagination
            val allItems = firstPageItems.toMutableList()
            var currentResponse = response
            val initialUrl = response.request.url.toString()

            for (page in 1 until maxPages) {
                val rawNextUrl = parseNextLink(currentResponse.headers["Link"]) ?: break
                val nextUrl = resolveUrl(currentResponse.request.url.toString(), rawNextUrl)

                if (!isSameOrigin(nextUrl, initialUrl)) {
                    throw FizzyException.Validation("Cross-origin pagination link rejected: $nextUrl (initial: $initialUrl)")
                }

                currentResponse = http.requestWithRetry(HttpMethod.Get, nextUrl)

                if (!currentResponse.status.isSuccess()) {
                    throw errorFromResponse(currentResponse)
                }

                val pageBody = currentResponse.bodyAsText()
                val pageItems = parseItems(pageBody)
                allItems.addAll(pageItems)

                // Check maxItems cap
                if (maxItems != null && maxItems > 0 && allItems.size >= maxItems) {
                    val duration = (currentTimeMillis() - startTime).millisToDuration()
                    val result = ListResult(allItems.take(maxItems), ListMeta(truncated = true))
                    hooks.safeOnOperationEnd(info, OperationResult(duration))
                    return result
                }
            }

            val hasMore = parseNextLink(currentResponse.headers["Link"]) != null
            val duration = (currentTimeMillis() - startTime).millisToDuration()
            val result = ListResult(allItems, ListMeta(hasMore))
            hooks.safeOnOperationEnd(info, OperationResult(duration))
            return result
        } catch (e: FizzyException) {
            val duration = (currentTimeMillis() - startTime).millisToDuration()
            hooks.safeOnOperationEnd(info, OperationResult(duration, e))
            throw e
        } catch (e: Exception) {
            val duration = (currentTimeMillis() - startTime).millisToDuration()
            hooks.safeOnOperationEnd(info, OperationResult(duration, e))
            throw e
        }
    }

    /**
     * Streaming paginated request that emits items as each page arrives.
     *
     * Unlike [requestPaginated] which eagerly loads all pages, this returns
     * a cold [Flow] that fetches pages lazily as the collector consumes items.
     * Useful for processing large datasets without loading everything into memory.
     *
     * ```kotlin
     * account.cards.listAsFlow(boardId)
     *     .collect { card -> println(card.title) }
     * ```
     *
     * @param info Operation metadata for hooks.
     * @param fn The suspend function that performs the initial HTTP call.
     * @param parseItems Parses a page's response body into a list of items.
     */
    protected fun <T> requestPaginatedAsFlow(
        info: OperationInfo,
        fn: suspend () -> HttpResponse,
        parseItems: (String) -> List<T>,
    ): Flow<T> = flow {
        val startTime = currentTimeMillis()
        hooks.safeOnOperationStart(info)

        try {
            var currentResponse = fn()

            if (!currentResponse.status.isSuccess()) {
                throw errorFromResponse(currentResponse)
            }

            val bodyText = currentResponse.bodyAsText()
            val firstPageItems = parseItems(bodyText)
            for (item in firstPageItems) emit(item)

            val initialUrl = currentResponse.request.url.toString()

            for (page in 1 until maxPages) {
                val rawNextUrl = parseNextLink(currentResponse.headers["Link"]) ?: break
                val nextUrl = resolveUrl(currentResponse.request.url.toString(), rawNextUrl)

                if (!isSameOrigin(nextUrl, initialUrl)) {
                    throw FizzyException.Validation("Cross-origin pagination link rejected: $nextUrl (initial: $initialUrl)")
                }

                currentResponse = http.requestWithRetry(HttpMethod.Get, nextUrl)

                if (!currentResponse.status.isSuccess()) {
                    throw errorFromResponse(currentResponse)
                }

                val pageBody = currentResponse.bodyAsText()
                val pageItems = parseItems(pageBody)
                for (item in pageItems) emit(item)
            }

            val duration = (currentTimeMillis() - startTime).millisToDuration()
            hooks.safeOnOperationEnd(info, OperationResult(duration))
        } catch (e: Exception) {
            val duration = (currentTimeMillis() - startTime).millisToDuration()
            hooks.safeOnOperationEnd(info, OperationResult(duration, e))
            throw e
        }
    }

    /** Converts an HTTP error response to a [FizzyException]. */
    private suspend fun errorFromResponse(response: HttpResponse): FizzyException {
        val status = response.status.value
        val requestId = response.headers["X-Request-Id"]
        val retryAfter = parseRetryAfter(response.headers["Retry-After"])

        var message: String = response.status.description.ifEmpty { "Request failed" }
        var hint: String? = null

        try {
            val bodyText = response.bodyAsText()
            if (bodyText.isNotBlank()) {
                val jsonBody = json.parseToJsonElement(bodyText)
                if (jsonBody is JsonObject) {
                    jsonBody["error"]?.jsonPrimitive?.content?.let {
                        message = FizzyException.truncateMessage(it)
                    }
                    jsonBody["message"]?.jsonPrimitive?.content?.let {
                        message = FizzyException.truncateMessage(it)
                    }
                    jsonBody["error_description"]?.jsonPrimitive?.content?.let {
                        hint = FizzyException.truncateMessage(it)
                    }
                }
            }
        } catch (_: Exception) {
            // Body is not JSON or empty -- use status text
        }

        return FizzyException.fromHttpStatus(status, message, hint, requestId, retryAfter)
    }

    companion object {
        /** Resolve a potentially relative URL against a base URL. */
        internal fun resolveUrl(base: String, relative: String): String {
            // If it's already absolute, return as-is
            if (relative.startsWith("http://") || relative.startsWith("https://")) {
                return relative
            }
            // Extract origin from base
            val schemeEnd = base.indexOf("://")
            if (schemeEnd < 0) return relative
            val afterScheme = schemeEnd + 3
            val pathStart = base.indexOf('/', afterScheme)
            val origin = if (pathStart < 0) base else base.substring(0, pathStart)
            val normalizedPath = if (relative.startsWith("/")) relative else "/$relative"
            return "$origin$normalizedPath"
        }
    }
}

/** Safely invoke onOperationStart, catching hook exceptions. */
private fun FizzyHooks.safeOnOperationStart(info: OperationInfo) {
    runCatching { onOperationStart(info) }
}

/** Safely invoke onOperationEnd, catching hook exceptions. */
private fun FizzyHooks.safeOnOperationEnd(info: OperationInfo, result: OperationResult) {
    runCatching { onOperationEnd(info, result) }
}

/** Convert Ktor headers to a simple map for pagination utilities. */
private fun io.ktor.http.Headers.toMap(): Map<String, List<String>> {
    val result = mutableMapOf<String, List<String>>()
    forEach { key, values -> result[key] = values }
    return result
}
