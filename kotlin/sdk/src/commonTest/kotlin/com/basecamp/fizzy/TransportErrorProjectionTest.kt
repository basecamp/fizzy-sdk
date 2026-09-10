package com.basecamp.fizzy

import io.ktor.client.engine.mock.*
import io.ktor.client.network.sockets.ConnectTimeoutException
import io.ktor.client.network.sockets.SocketTimeoutException
import io.ktor.client.plugins.HttpRequestTimeoutException
import io.ktor.http.*
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertSame
import kotlin.test.assertTrue

/**
 * A request that fails in transport must not put its URL's query into any
 * rendering of the error. Ktor's timeout exceptions render the request URL in
 * their message, so a signed query on the request reached the SDK error's
 * message, `toString()`, stack trace, cause chain and the request-end hook's
 * `RequestResult.error`.
 */
class TransportErrorProjectionTest {
    private val secret = "SECRETVALUE"
    private val signed = "http://localhost:3000/blob?signature=$secret"

    private class EndSpy : FizzyHooks {
        val errors = mutableListOf<Throwable?>()
        override fun onRequestEnd(info: RequestInfo, result: RequestResult) { errors += result.error }
    }

    private fun renderings(e: Throwable?, label: String = "error", depth: Int = 0): List<Pair<String, String>> {
        if (e == null || depth > 8) return emptyList()
        val own = listOf(
            "$label.message" to (e.message ?: ""),
            "$label.toString" to e.toString(),
            "$label.stackTrace" to e.stackTraceToString(),
            "$label.hint" to ((e as? FizzyException)?.hint ?: ""),
        )
        return own + renderings(e.cause, "$label.cause", depth + 1)
    }

    private fun assertNoSecret(e: Throwable?, context: String) {
        for ((label, text) in renderings(e)) {
            assertFalse(text.contains(secret), "$context: the signed query leaked into $label: $text")
        }
    }

    private fun clientThrowing(spy: EndSpy, failure: (io.ktor.client.request.HttpRequestData) -> Throwable) =
        FizzyClient {
            accessToken("test-token")
            baseUrl = "http://localhost:3000"
            enableRetry = false
            hooks = spy
            engine = MockEngine { request -> throw failure(request) }
        }

    @Test
    fun requestTimeoutRendersNoSignedQuery() = runTest {
        val spy = EndSpy()
        // The exception the HttpTimeout plugin throws, built from the request it timed out.
        val client = clientThrowing(spy) { request -> HttpRequestTimeoutException(request) }

        val e = assertFailsWith<FizzyException.Network> {
            client.httpClient.requestWithRetry(HttpMethod.Get, signed)
        }

        assertIs<HttpRequestTimeoutException>(e.cause, "the cause still classifies as the timeout")
        assertEquals("Network error: Request timeout has expired [url=http://localhost:3000/blob, request_timeout=30000 ms]", e.message)
        assertNoSecret(e, "thrown error")
        assertEquals(1, spy.errors.size)
        assertIs<HttpRequestTimeoutException>(spy.errors.single(), "the request-end hook sees the projected error")
        assertNoSecret(spy.errors.single(), "RequestResult.error")
        client.close()
    }

    @Test
    fun connectAndSocketTimeoutsRenderNoSignedQuery() = runTest {
        val failures: List<(String) -> Throwable> = listOf(
            { url -> ConnectTimeoutException("Connect timeout has expired [url=$url, connect_timeout=1 ms]") },
            { url -> SocketTimeoutException("Socket timeout has expired [url=$url, socket_timeout=1 ms]") },
        )
        for (failure in failures) {
            val spy = EndSpy()
            val client = clientThrowing(spy) { request -> failure(request.url.toString()) }
            val e = assertFailsWith<FizzyException.Network> {
                client.httpClient.requestWithRetry(HttpMethod.Get, signed)
            }
            assertTrue(e.message!!.contains("[url=http://localhost:3000/blob, "), e.message)
            assertNoSecret(e, "thrown error")
            assertNoSecret(spy.errors.single(), "RequestResult.error")
            client.close()
        }
    }

    @Test
    fun binaryRequestTimeoutRendersNoSignedQuery() = runTest {
        val spy = EndSpy()
        val client = clientThrowing(spy) { request -> HttpRequestTimeoutException(request) }

        val e = assertFailsWith<FizzyException.Network> {
            client.httpClient.requestBinaryWithRetry(HttpMethod.Put, signed, byteArrayOf(1, 2, 3), "application/octet-stream")
        }

        assertIs<HttpRequestTimeoutException>(e.cause)
        assertTrue(e.message!!.startsWith("Network error: Request timeout has expired [url=http://localhost:3000/blob,"), e.message)
        assertNoSecret(e, "thrown error")
        assertNoSecret(spy.errors.single(), "RequestResult.error")
        client.close()
    }

    @Test
    fun otherTransportFailuresPassThroughUnchanged() = runTest {
        val spy = EndSpy()
        val refused = java.io.IOException("Connection refused")
        val client = clientThrowing(spy) { refused }

        val e = assertFailsWith<FizzyException.Network> {
            client.httpClient.requestWithRetry(HttpMethod.Get, signed)
        }

        assertEquals("Network error: Connection refused", e.message)
        // Compared by class and message: the coroutine test dispatcher's
        // stack-trace recovery hands the handler a copy of the thrown instance.
        val cause = assertIs<java.io.IOException>(e.cause, "a transport diagnostic that renders no URL keeps its class")
        assertEquals("Connection refused", cause.message)
        assertSame(cause, spy.errors.single(), "the request-end hook sees the same error the caller does")
        client.close()
    }

    @Test
    fun projectionKeepsPathOnTheTrustedOriginAndOriginOnlyElsewhere() {
        val onApi = redactTransportError(HttpRequestTimeoutException(signed, 5), signed, "http://localhost:3000", 5)
        assertEquals("Request timeout has expired [url=http://localhost:3000/blob, request_timeout=5 ms]", onApi.message)

        val elsewhere = redactTransportError(HttpRequestTimeoutException(signed, 5), signed, "https://fizzy.do", 5)
        assertEquals("Request timeout has expired [url=http://localhost:3000, request_timeout=5 ms]", elsewhere.message)

        val withUserinfo = "http://user:pass@localhost:3000/blob?signature=$secret"
        val userinfo = redactTransportError(HttpRequestTimeoutException(withUserinfo, null), withUserinfo, "http://localhost:3000")
        assertEquals("Request timeout has expired [url=http://localhost:3000, request_timeout=unknown ms]", userinfo.message)

        val unparsable = redactTransportError(HttpRequestTimeoutException("://nope", null), "://nope")
        assertEquals("Request timeout has expired [url=unparsable, request_timeout=unknown ms]", unparsable.message)
    }
}
