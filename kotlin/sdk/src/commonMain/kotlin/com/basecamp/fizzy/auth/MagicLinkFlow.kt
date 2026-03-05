package com.basecamp.fizzy.auth

import com.basecamp.fizzy.*
import com.basecamp.fizzy.http.FizzyHttpClient
import io.ktor.client.*
import io.ktor.client.engine.*
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import kotlinx.serialization.json.*

/**
 * Passwordless authentication via magic links.
 *
 * This flow uses an unauthenticated client to:
 * 1. Request a magic link email via [requestMagicLink]
 * 2. Redeem the token from the link via [redeemMagicLink]
 * 3. Optionally complete signup for new users via [completeSignup]
 *
 * The resulting session token can be used with [CookieAuth].
 *
 * ```kotlin
 * val flow = MagicLinkFlow(baseUrl = "https://fizzy.do")
 *
 * // Step 1: Request magic link
 * flow.requestMagicLink("user@example.com")
 *
 * // Step 2: User clicks email link, extract token
 * val session = flow.redeemMagicLink(pendingAuthToken)
 *
 * // Step 3: Create authenticated client
 * val client = FizzyClient {
 *     auth(CookieAuth(session.sessionToken))
 * }
 * ```
 */
class MagicLinkFlow(
    private val baseUrl: String = FizzyConfig.DEFAULT_BASE_URL,
    engine: HttpClientEngine? = null,
) {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    private val httpClient: HttpClient = if (engine != null) {
        HttpClient(engine) { configureClient() }
    } else {
        HttpClient { configureClient() }
    }

    private fun HttpClientConfig<*>.configureClient() {
        expectSuccess = false
        install(HttpTimeout) {
            requestTimeoutMillis = 30_000
            connectTimeoutMillis = 30_000
            socketTimeoutMillis = 30_000
        }
    }

    /**
     * Result of a magic link request.
     *
     * @property pendingAuthenticationToken Token to use when redeeming the magic link.
     */
    data class MagicLinkRequest(
        val pendingAuthenticationToken: String,
    )

    /**
     * Result of redeeming a magic link.
     *
     * @property sessionToken Session token for authenticated requests.
     * @property requiresSignupCompletion Whether the user needs to complete signup.
     */
    data class MagicLinkSession(
        val sessionToken: String,
        val requiresSignupCompletion: Boolean,
    )

    /**
     * Request a magic link email be sent to the given address.
     *
     * @param emailAddress The email to send the magic link to.
     * @return A [MagicLinkRequest] with the pending authentication token.
     */
    suspend fun requestMagicLink(emailAddress: String): MagicLinkRequest {
        val response = httpClient.request("$baseUrl/api/sessions") {
            method = HttpMethod.Post
            header(HttpHeaders.ContentType, "application/json")
            header(HttpHeaders.Accept, "application/json")
            setBody(buildJsonObject { put("email_address", emailAddress) }.toString())
        }

        if (!response.status.isSuccess()) {
            throw errorFromResponse(response)
        }

        val body = json.parseToJsonElement(response.bodyAsText()).jsonObject
        val token = body["pending_authentication_token"]?.jsonPrimitive?.content
            ?: throw FizzyException.Api("Missing pending_authentication_token in response", 0)

        return MagicLinkRequest(pendingAuthenticationToken = token)
    }

    /**
     * Redeem a magic link token to obtain a session.
     *
     * @param pendingAuthenticationToken The token from the magic link email.
     * @return A [MagicLinkSession] with the session token.
     */
    suspend fun redeemMagicLink(pendingAuthenticationToken: String): MagicLinkSession {
        val response = httpClient.request("$baseUrl/api/sessions/redeem") {
            method = HttpMethod.Post
            header(HttpHeaders.ContentType, "application/json")
            header(HttpHeaders.Accept, "application/json")
            setBody(buildJsonObject { put("pending_authentication_token", pendingAuthenticationToken) }.toString())
        }

        if (!response.status.isSuccess()) {
            throw errorFromResponse(response)
        }

        val body = json.parseToJsonElement(response.bodyAsText()).jsonObject
        val sessionToken = body["session_token"]?.jsonPrimitive?.content
            ?: throw FizzyException.Api("Missing session_token in response", 0)
        val requiresSignup = body["requires_signup_completion"]?.jsonPrimitive?.content?.toBoolean() ?: false

        return MagicLinkSession(
            sessionToken = sessionToken,
            requiresSignupCompletion = requiresSignup,
        )
    }

    /**
     * Complete signup for a new user after redeeming a magic link.
     *
     * @param sessionToken The session token from [redeemMagicLink].
     * @param name The user's display name.
     */
    suspend fun completeSignup(sessionToken: String, name: String) {
        val response = httpClient.request("$baseUrl/api/sessions/signup") {
            method = HttpMethod.Post
            header(HttpHeaders.ContentType, "application/json")
            header(HttpHeaders.Accept, "application/json")
            header("Cookie", "session_token=$sessionToken")
            setBody(buildJsonObject { put("name", name) }.toString())
        }

        if (!response.status.isSuccess()) {
            throw errorFromResponse(response)
        }
    }

    /** Clean up the internal HTTP client. */
    fun close() {
        httpClient.close()
    }

    private suspend fun errorFromResponse(response: HttpResponse): FizzyException {
        val status = response.status.value
        val requestId = response.headers["X-Request-Id"]

        var message: String = response.status.description.ifEmpty { "Request failed" }
        var hint: String? = null

        try {
            val bodyText = response.bodyAsText()
            if (bodyText.isNotBlank()) {
                val jsonBody = json.parseToJsonElement(bodyText)
                if (jsonBody is kotlinx.serialization.json.JsonObject) {
                    jsonBody["error"]?.jsonPrimitive?.content?.let {
                        message = FizzyException.truncateMessage(it)
                    }
                    jsonBody["message"]?.jsonPrimitive?.content?.let {
                        message = FizzyException.truncateMessage(it)
                    }
                }
            }
        } catch (_: Exception) {
            // Body is not JSON or empty
        }

        return FizzyException.fromHttpStatus(status, message, hint, requestId)
    }
}
