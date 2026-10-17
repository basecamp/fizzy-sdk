package com.basecamp.fizzy

import com.basecamp.fizzy.auth.MagicLinkFlow
import io.ktor.client.engine.mock.*
import io.ktor.client.request.*
import io.ktor.http.*
import io.ktor.http.content.*
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** The magic-link flow speaks Fizzy's sessions contract: the paths, bodies, cookie and statuses it serves. */
class MagicLinkFlowTest {
    private val base = "https://app.fizzy.test"

    private fun bodyOf(request: HttpRequestData): JsonObject {
        val content = request.body as TextContent
        return Json.parseToJsonElement(content.text).jsonObject
    }

    @Test
    fun aSignInStartsAtSessionAndRedeemsTheCodeWithThePendingCookie() = runTest {
        val seen = mutableListOf<HttpRequestData>()
        val engine = MockEngine { request ->
            seen += request
            when (request.url.encodedPath) {
                "/session.json" -> respond("""{"pending_authentication_token":"pend/1+2="}""", HttpStatusCode.Created, headersOf(HttpHeaders.ContentType, "application/json"))
                "/session/magic_link.json" -> respond("""{"session_token":"st-1","requires_signup_completion":true}""", HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "application/json"))
                else -> respond("", HttpStatusCode.NotFound)
            }
        }
        val flow = MagicLinkFlow(baseUrl = base, engine = engine)

        val pending = flow.requestMagicLink("ada@example.com")
        assertEquals("pend/1+2=", pending.pendingAuthenticationToken)
        assertEquals("pend/1+2=", flow.pendingToken)

        val session = flow.redeemMagicLink("ABC123")
        assertEquals("st-1", session.sessionToken)
        assertTrue(session.requiresSignupCompletion)

        assertEquals(HttpMethod.Post, seen[0].method)
        assertEquals("/session.json", seen[0].url.encodedPath)
        assertEquals("ada@example.com", bodyOf(seen[0])["email_address"]?.jsonPrimitive?.content)
        assertNull(seen[0].headers[HttpHeaders.Cookie], "no cookie before a sign-in is pending")

        assertEquals(HttpMethod.Post, seen[1].method)
        assertEquals("/session/magic_link.json", seen[1].url.encodedPath)
        assertEquals(mapOf("code" to "ABC123"), bodyOf(seen[1]).mapValues { it.value.jsonPrimitive.content })
        assertEquals("pending_authentication_token=pend%2F1%2B2%3D", seen[1].headers[HttpHeaders.Cookie])
        flow.close()
    }

    @Test
    fun aResumedSignInRedeemsWithTheTokenItWasGiven() = runTest {
        var cookie: String? = null
        val engine = MockEngine { request ->
            cookie = request.headers[HttpHeaders.Cookie]
            respond("""{"session_token":"st-2","requires_signup_completion":false}""", HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "application/json"))
        }
        val flow = MagicLinkFlow(baseUrl = base, engine = engine, pendingToken = "pend-9")
        assertEquals("st-2", flow.redeemMagicLink("XYZ").sessionToken)
        assertEquals("pending_authentication_token=pend-9", cookie)

        val other = MagicLinkFlow(baseUrl = base, engine = engine)
        other.resume("pend-10")
        other.redeemMagicLink("XYZ")
        assertEquals("pending_authentication_token=pend-10", cookie)
    }

    @Test
    fun redeemingWithNoSignInPendingIsAUsageError() = runTest {
        val engine = MockEngine { respond("", HttpStatusCode.InternalServerError) }
        val flow = MagicLinkFlow(baseUrl = base, engine = engine)
        assertFailsWith<FizzyException.Usage> { flow.redeemMagicLink("ABC123") }
        assertTrue(engine.requestHistory.isEmpty(), "nothing is sent without a pending sign-in")
    }

    @Test
    fun aRefusedCodeIsAnAuthError() = runTest {
        val engine = MockEngine {
            respond("""{"message":"Try another code."}""", HttpStatusCode.Unauthorized, headersOf(HttpHeaders.ContentType, "application/json"))
        }
        val flow = MagicLinkFlow(baseUrl = base, engine = engine, pendingToken = "pend-1")
        assertFailsWith<FizzyException.Auth> { flow.redeemMagicLink("WRONG") }
        assertEquals(1, engine.requestHistory.size, "a refused code is not resent")
    }

    @Test
    fun signupCompletesWithTheFullNameOnTheSessionCookieAndAnEmpty201() = runTest {
        val engine = MockEngine { respond("", HttpStatusCode.Created) }
        val flow = MagicLinkFlow(baseUrl = base, engine = engine)

        flow.completeSignup("st-1", "Ada Lovelace")

        val request = engine.requestHistory.single()
        assertEquals(HttpMethod.Post, request.method)
        assertEquals("/signup/completion.json", request.url.encodedPath)
        assertEquals("Ada Lovelace", bodyOf(request)["full_name"]?.jsonPrimitive?.content)
        assertEquals("session_token=st-1", request.headers[HttpHeaders.Cookie])
    }
}
