package com.basecamp.fizzy.auth

import com.basecamp.fizzy.AuthStrategy
import com.basecamp.fizzy.FizzyClient
import com.basecamp.fizzy.FizzyConfig
import com.basecamp.fizzy.FizzyException
import com.basecamp.fizzy.generated.services.CompleteSignupBody
import com.basecamp.fizzy.generated.services.CreateSessionBody
import com.basecamp.fizzy.generated.services.RedeemMagicLinkBody
import com.basecamp.fizzy.generated.sessions
import io.ktor.client.engine.*
import io.ktor.client.request.*
import io.ktor.http.*

/**
 * Passwordless sign-in with a magic link, on the generated Sessions operations.
 *
 * 1. [requestMagicLink] starts a sign-in (`POST /session.json`). Fizzy emails a code and
 *    answers a pending authentication token, which this flow keeps.
 * 2. [redeemMagicLink] trades the code from the email for a session token
 *    (`POST /session/magic_link.json`). Fizzy reads the pending sign-in from the
 *    `pending_authentication_token` cookie, so the flow sends it as one.
 * 3. [completeSignup] names a new user when the session says signup is incomplete.
 *
 * A sign-in that finishes in another process resumes from [pendingToken], passed back as
 * `pendingToken` when building the flow or with [resume].
 *
 * ```kotlin
 * val flow = MagicLinkFlow(baseUrl = "https://app.fizzy.do")
 * flow.requestMagicLink("user@example.com")
 * val session = flow.redeemMagicLink(codeFromEmail)
 * if (session.requiresSignupCompletion) flow.completeSignup(session.sessionToken, "Ada Lovelace")
 * val client = FizzyClient { auth(CookieAuth(session.sessionToken)) }
 * ```
 */
class MagicLinkFlow(
    private val baseUrl: String = FizzyConfig.DEFAULT_BASE_URL,
    private val engine: HttpClientEngine? = null,
    pendingToken: String? = null,
) {
    /** The pending authentication token of the sign-in under way, or null before one starts. */
    var pendingToken: String? = pendingToken?.takeIf { it.isNotBlank() }
        private set

    /** Carries the pending sign-in's cookie on the requests that need it, and nothing otherwise. */
    private val pendingAuth = AuthStrategy { request ->
        this.pendingToken?.let { request.header(HttpHeaders.Cookie, cookie(PENDING_COOKIE, it)) }
    }

    private val client: FizzyClient = client(pendingAuth)

    private fun client(auth: AuthStrategy): FizzyClient = FizzyClient {
        baseUrl = this@MagicLinkFlow.baseUrl
        engine = this@MagicLinkFlow.engine
        auth(auth)
    }

    /**
     * Result of starting a sign-in.
     *
     * @property pendingAuthenticationToken The token [redeemMagicLink] sends back as a cookie.
     */
    data class MagicLinkRequest(
        val pendingAuthenticationToken: String,
    )

    /**
     * Result of redeeming a magic-link code.
     *
     * @property sessionToken Session token for [CookieAuth].
     * @property requiresSignupCompletion Whether the user must still [completeSignup].
     */
    data class MagicLinkSession(
        val sessionToken: String,
        val requiresSignupCompletion: Boolean,
    )

    /**
     * Starts a sign-in: Fizzy emails [emailAddress] a code and answers the pending token,
     * which this flow keeps for [redeemMagicLink]. Fizzy answers the same for an address it
     * does not know, so the answer says nothing about whether the account exists.
     */
    suspend fun requestMagicLink(emailAddress: String): MagicLinkRequest {
        val pending = client.forAccount(ROOT).sessions.create(CreateSessionBody(emailAddress = emailAddress))
        pendingToken = pending.pendingAuthenticationToken
        return MagicLinkRequest(pendingAuthenticationToken = pending.pendingAuthenticationToken)
    }

    /** Resumes a sign-in another process started, from its [pendingToken]. */
    fun resume(pendingToken: String) {
        require(pendingToken.isNotBlank()) { "Pending token must not be blank" }
        this.pendingToken = pendingToken
    }

    /**
     * Redeems the [code] from the magic-link email for a session.
     *
     * @throws FizzyException.Usage when no sign-in is pending: call [requestMagicLink] or [resume] first.
     * @throws FizzyException.Auth when Fizzy refuses the code or the pending sign-in.
     */
    suspend fun redeemMagicLink(code: String): MagicLinkSession {
        if (pendingToken == null) {
            throw FizzyException.Usage(
                "No sign-in is pending",
                hint = "Call requestMagicLink first, or resume with the pending token",
            )
        }
        val session = client.forAccount(ROOT).sessions.redeemMagicLink(RedeemMagicLinkBody(code = code))
        return MagicLinkSession(
            sessionToken = session.sessionToken,
            requiresSignupCompletion = session.requiresSignupCompletion,
        )
    }

    /**
     * Completes signup for a new user, signed in with the [sessionToken] [redeemMagicLink] answered.
     *
     * @param fullName The user's full name.
     */
    suspend fun completeSignup(sessionToken: String, fullName: String) {
        val signedIn = client(CookieAuth(sessionToken))
        try {
            signedIn.forAccount(ROOT).sessions.completeSignup(CompleteSignupBody(fullName = fullName))
        } finally {
            signedIn.close()
        }
    }

    /** Releases the flow's HTTP client. */
    fun close() {
        client.close()
    }

    internal companion object {
        const val PENDING_COOKIE = "pending_authentication_token"

        /**
         * Sessions are root-scoped: the generated operations ignore the account, so any id
         * reaches them.
         */
        const val ROOT = "0"

        /** A cookie pair whose value is percent-encoded, so no character of a token can end it. */
        fun cookie(name: String, value: String): String = "$name=${value.encodeURLParameter()}"
    }
}
