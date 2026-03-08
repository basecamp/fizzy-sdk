package com.basecamp.fizzy

import com.basecamp.fizzy.generated.boards
import io.ktor.client.engine.mock.*
import io.ktor.http.*
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertTrue
import kotlin.test.assertFalse
import kotlin.test.assertFailsWith

class FizzyTest {

    // -- FizzyException type defaults --

    @Test
    fun testAuthExceptionDefaults() {
        val e = FizzyException.Auth()
        assertEquals(FizzyException.CODE_AUTH, e.code)
        assertEquals(401, e.httpStatus)
        assertFalse(e.retryable)
        assertEquals(3, e.exitCode)
    }

    @Test
    fun testForbiddenExceptionDefaults() {
        val e = FizzyException.Forbidden()
        assertEquals(FizzyException.CODE_FORBIDDEN, e.code)
        assertEquals(403, e.httpStatus)
        assertFalse(e.retryable)
        assertEquals(4, e.exitCode)
    }

    @Test
    fun testNotFoundExceptionDefaults() {
        val e = FizzyException.NotFound()
        assertEquals(FizzyException.CODE_NOT_FOUND, e.code)
        assertEquals(404, e.httpStatus)
        assertFalse(e.retryable)
        assertEquals(2, e.exitCode)
    }

    @Test
    fun testRateLimitExceptionDefaults() {
        val e = FizzyException.RateLimit()
        assertEquals(FizzyException.CODE_RATE_LIMIT, e.code)
        assertEquals(429, e.httpStatus)
        assertTrue(e.retryable)
        assertEquals(5, e.exitCode)
    }

    @Test
    fun testNetworkExceptionDefaults() {
        val e = FizzyException.Network()
        assertEquals(FizzyException.CODE_NETWORK, e.code)
        assertEquals(null, e.httpStatus)
        assertTrue(e.retryable)
        assertEquals(6, e.exitCode)
    }

    @Test
    fun testApiExceptionDefaults() {
        val e = FizzyException.Api("Server error", 500)
        assertEquals(FizzyException.CODE_API, e.code)
        assertEquals(500, e.httpStatus)
        assertTrue(e.retryable)
        assertEquals(7, e.exitCode)
    }

    @Test
    fun testApiExceptionNon5xxNotRetryable() {
        val e = FizzyException.Api("Bad gateway", 502)
        assertTrue(e.retryable)
        val e2 = FizzyException.Api("Teapot", 418, retryable = false)
        assertFalse(e2.retryable)
    }

    @Test
    fun testValidationExceptionDefaults() {
        val e = FizzyException.Validation("Invalid input")
        assertEquals(FizzyException.CODE_VALIDATION, e.code)
        assertEquals(422, e.httpStatus)
        assertFalse(e.retryable)
        assertEquals(9, e.exitCode)
    }

    @Test
    fun testAmbiguousExceptionDefaults() {
        val e = FizzyException.Ambiguous("card", listOf("Card A", "Card B"))
        assertEquals(FizzyException.CODE_AMBIGUOUS, e.code)
        assertEquals(null, e.httpStatus)
        assertFalse(e.retryable)
        assertEquals(8, e.exitCode)
        assertEquals("card", e.resource)
        assertEquals(listOf("Card A", "Card B"), e.matches)
    }

    @Test
    fun testUsageExceptionDefaults() {
        val e = FizzyException.Usage("Bad argument")
        assertEquals(FizzyException.CODE_USAGE, e.code)
        assertEquals(null, e.httpStatus)
        assertFalse(e.retryable)
        assertEquals(1, e.exitCode)
    }

    // -- exitCodeFor mapping --

    @Test
    fun testExitCodeMapping() {
        assertEquals(1, FizzyException.exitCodeFor(FizzyException.CODE_USAGE))
        assertEquals(2, FizzyException.exitCodeFor(FizzyException.CODE_NOT_FOUND))
        assertEquals(3, FizzyException.exitCodeFor(FizzyException.CODE_AUTH))
        assertEquals(4, FizzyException.exitCodeFor(FizzyException.CODE_FORBIDDEN))
        assertEquals(5, FizzyException.exitCodeFor(FizzyException.CODE_RATE_LIMIT))
        assertEquals(6, FizzyException.exitCodeFor(FizzyException.CODE_NETWORK))
        assertEquals(7, FizzyException.exitCodeFor(FizzyException.CODE_API))
        assertEquals(8, FizzyException.exitCodeFor(FizzyException.CODE_AMBIGUOUS))
        assertEquals(9, FizzyException.exitCodeFor(FizzyException.CODE_VALIDATION))
    }

    @Test
    fun testExitCodeForUnknownDefaultsToApi() {
        assertEquals(7, FizzyException.exitCodeFor("unknown_code"))
    }

    // -- fromHttpStatus factory --

    @Test
    fun testFromHttpStatus401() {
        assertIs<FizzyException.Auth>(FizzyException.fromHttpStatus(401))
    }

    @Test
    fun testFromHttpStatus403() {
        assertIs<FizzyException.Forbidden>(FizzyException.fromHttpStatus(403))
    }

    @Test
    fun testFromHttpStatus404() {
        assertIs<FizzyException.NotFound>(FizzyException.fromHttpStatus(404))
    }

    @Test
    fun testFromHttpStatus429() {
        assertIs<FizzyException.RateLimit>(FizzyException.fromHttpStatus(429))
    }

    @Test
    fun testFromHttpStatus422() {
        assertIs<FizzyException.Validation>(FizzyException.fromHttpStatus(422))
    }

    @Test
    fun testFromHttpStatus400() {
        assertIs<FizzyException.Validation>(FizzyException.fromHttpStatus(400))
    }

    @Test
    fun testFromHttpStatus500() {
        assertIs<FizzyException.Api>(FizzyException.fromHttpStatus(500))
    }

    @Test
    fun testFromHttpStatus503() {
        val e = FizzyException.fromHttpStatus(503)
        assertIs<FizzyException.Api>(e)
        assertTrue(e.retryable)
    }

    @Test
    fun testFromHttpStatusRetryAfterPassedThrough() {
        val e = FizzyException.fromHttpStatus(429, retryAfterSeconds = 30)
        assertIs<FizzyException.RateLimit>(e)
        assertEquals(30, e.retryAfterSeconds)
    }

    @Test
    fun testFromHttpStatusRequestIdPassedThrough() {
        val e = FizzyException.fromHttpStatus(404, requestId = "req-123")
        assertIs<FizzyException.NotFound>(e)
        assertEquals("req-123", e.requestId)
    }

    // -- Error message truncation --

    @Test
    fun testShortMessageNotTruncated() {
        val msg = "Short error"
        assertEquals(msg, FizzyException.truncateMessage(msg))
    }

    @Test
    fun testLongMessageTruncated() {
        val msg = "x".repeat(600)
        val truncated = FizzyException.truncateMessage(msg)
        assertTrue(truncated.length <= 500)
        assertTrue(truncated.endsWith("..."))
    }

    @Test
    fun testExactLengthNotTruncated() {
        val msg = "x".repeat(500)
        assertEquals(msg, FizzyException.truncateMessage(msg))
    }

    // -- FizzyConfig defaults --

    @Test
    fun testConfigDefaults() {
        val config = FizzyConfig()
        assertEquals("https://fizzy.do", config.baseUrl)
        assertTrue(config.userAgent.contains("fizzy-sdk-kotlin"))
        assertFalse(config.enableCache)
        assertTrue(config.enableRetry)
    }

    @Test
    fun testConfigMaxPagesDefault() {
        val config = FizzyConfig()
        assertEquals(10_000, config.maxPages)
    }

    @Test
    fun testConfigMaxRetriesDefault() {
        val config = FizzyConfig()
        assertEquals(3, config.maxRetries)
    }

    // -- Pagination utilities --

    @Test
    fun testParseNextLinkValid() {
        val link = """<https://fizzy.do/999/boards.json?page=2>; rel="next""""
        assertEquals("https://fizzy.do/999/boards.json?page=2", parseNextLink(link))
    }

    @Test
    fun testParseNextLinkNull() {
        assertEquals(null, parseNextLink(null))
        assertEquals(null, parseNextLink(""))
        assertEquals(null, parseNextLink("   "))
    }

    @Test
    fun testParseNextLinkNoNext() {
        val link = """<https://fizzy.do/999/boards.json?page=1>; rel="prev""""
        assertEquals(null, parseNextLink(link))
    }

    @Test
    fun testIsSameOriginSame() {
        assertTrue(isSameOrigin("https://fizzy.do/boards", "https://fizzy.do/cards"))
    }

    @Test
    fun testIsSameOriginDifferent() {
        assertFalse(isSameOrigin("https://fizzy.do/boards", "https://evil.com/boards"))
    }

    @Test
    fun testIsSameOriginDifferentScheme() {
        assertFalse(isSameOrigin("https://fizzy.do/boards", "http://fizzy.do/boards"))
    }

    @Test
    fun testCrossOriginPaginationThrows() = runTest {
        // MockEngine returns a valid first page with a cross-origin Link header.
        // The real requestPaginated code in BaseService must reject it.
        val mockEngine = MockEngine { request ->
            respond(
                content = """[{"id":1,"name":"Board","all_access":true,"created_at":"2026-01-01T00:00:00Z","url":"https://fizzy.do/999/boards/1"}]""",
                status = HttpStatusCode.OK,
                headers = headersOf(
                    HttpHeaders.ContentType to listOf("application/json"),
                    HttpHeaders.Link to listOf("""<https://evil.com/boards?page=2>; rel="next""""),
                ),
            )
        }

        val client = FizzyClient(
            authStrategy = BearerAuth(StaticTokenProvider("test-token")),
            config = FizzyConfig(baseUrl = "https://fizzy.do", userAgent = "test/1.0"),
            hooks = NoopHooks,
            engine = mockEngine,
            externalHttpClient = null,
        )

        val account = client.forAccount("999")
        val ex = assertFailsWith<FizzyException.Validation> {
            account.boards.list()
        }
        assertTrue(ex.message!!.contains("Cross-origin"))
        assertTrue(ex.message!!.contains("evil.com"))
        client.close()
    }

    @Test
    fun testParseRetryAfterValid() {
        assertEquals(5, parseRetryAfter("5"))
    }

    @Test
    fun testParseRetryAfterNull() {
        assertEquals(null, parseRetryAfter(null))
        assertEquals(null, parseRetryAfter(""))
        assertEquals(null, parseRetryAfter("abc"))
    }

    @Test
    fun testParseRetryAfterZero() {
        assertEquals(null, parseRetryAfter("0"))
    }
}
