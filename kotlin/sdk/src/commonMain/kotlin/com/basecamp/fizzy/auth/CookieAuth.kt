package com.basecamp.fizzy.auth

import com.basecamp.fizzy.AuthStrategy
import io.ktor.client.request.*

/**
 * Cookie-based authentication strategy for Fizzy.
 *
 * Uses a session token in the `Cookie` header. This is the authentication
 * method used by the Fizzy web and mobile apps.
 *
 * ```kotlin
 * val client = FizzyClient {
 *     auth(CookieAuth("session_token_here"))
 * }
 * ```
 */
class CookieAuth(private val sessionToken: String) : AuthStrategy {
    init {
        require(sessionToken.isNotBlank()) { "Session token must not be blank" }
    }

    override suspend fun authenticate(request: HttpRequestBuilder) {
        request.header("Cookie", "session_token=$sessionToken")
    }
}
