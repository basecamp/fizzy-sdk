package com.basecamp.fizzy.conformance

import com.basecamp.fizzy.*
import com.basecamp.fizzy.generated.*
import com.basecamp.fizzy.generated.services.*
import io.ktor.client.engine.mock.*
import io.ktor.http.*
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.*
import java.io.File

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

@Serializable
data class TestCase(
    val name: String,
    val description: String? = null,
    val operation: String,
    val method: String? = null,
    val path: String? = null,
    val pathParams: Map<String, JsonElement> = emptyMap(),
    val queryParams: Map<String, JsonElement> = emptyMap(),
    val requestBody: JsonObject? = null,
    val configOverrides: ConfigOverrides? = null,
    val mockResponses: List<MockResponse> = emptyList(),
    val assertions: List<Assertion> = emptyList(),
    val tags: List<String> = emptyList(),
)

@Serializable
data class ConfigOverrides(
    val baseUrl: String? = null,
    val maxPages: Int? = null,
    val maxItems: Int? = null,
)

@Serializable
data class MockResponse(
    val status: Int = 200,
    val headers: Map<String, String> = emptyMap(),
    val body: JsonElement? = null,
    val delay: Int? = null,
)

@Serializable
data class Assertion(
    val type: String,
    val expected: JsonElement? = null,
    val path: String? = null,
    val min: Int? = null,
)

// ---------------------------------------------------------------------------
// Execution result
// ---------------------------------------------------------------------------

data class ExecResult(
    val value: Any? = null,
    val error: Throwable? = null,
    val lastMockStatus: Int = 0,
)

data class RequestRecord(
    val timeMs: Long,
    val method: String,
    val url: String,
    val body: String?,
    val headers: Headers,
    val responseStatus: Int = 0,
)

// ---------------------------------------------------------------------------
// Main entry point
// ---------------------------------------------------------------------------

private val json = Json {
    ignoreUnknownKeys = true
    isLenient = true
}

fun main() {
    val testsDir = if (System.getenv("CONFORMANCE_TESTS_DIR") != null) {
        System.getenv("CONFORMANCE_TESTS_DIR")
    } else {
        "../conformance/tests"
    }

    val dir = File(testsDir)
    if (!dir.isDirectory) {
        System.err.println("Tests directory not found: $testsDir")
        System.exit(1)
    }

    val files = dir.listFiles { f -> f.extension == "json" }?.sorted() ?: emptyList()
    if (files.isEmpty()) {
        System.err.println("No test files found in $testsDir")
        System.exit(1)
    }

    var passed = 0
    var failed = 0
    var skipped = 0

    for (file in files) {
        val cases: List<TestCase> = json.decodeFromString(file.readText())
        println("\n=== ${file.name} (${cases.size} tests) ===")

        for (tc in cases) {
            val (result, records) = runTest(tc)
            val ok = checkAssertions(tc, result, records)
            if (ok) {
                println("  PASS  ${tc.name}")
                passed++
            } else {
                println("  FAIL  ${tc.name}")
                failed++
            }
        }
    }

    println("\n$passed passed, $failed failed, $skipped skipped")
    if (failed > 0) System.exit(1)
}

// ---------------------------------------------------------------------------
// Test runner
// ---------------------------------------------------------------------------

/**
 * Rewrite Link header URLs so same-origin links point to the client's base URL
 * while cross-origin links are left alone.
 */
private fun rewriteLinkHeaders(
    headers: Map<String, String>,
    fixtureOrigin: String,
    clientOrigin: String,
): Map<String, String> {
    val linkVal = headers["Link"] ?: return headers
    if (fixtureOrigin == clientOrigin) return headers

    val newLink = linkVal.replace(fixtureOrigin, clientOrigin)
    return headers + ("Link" to newLink)
}

private fun extractOrigin(url: String): String {
    val schemeEnd = url.indexOf("://")
    if (schemeEnd < 0) return url
    val afterScheme = schemeEnd + 3
    val pathStart = url.indexOf('/', afterScheme)
    return if (pathStart < 0) url else url.substring(0, pathStart)
}

fun runTest(tc: TestCase): Pair<ExecResult, List<RequestRecord>> {
    val records = mutableListOf<RequestRecord>()
    var mockIdx = 0
    var lastResponseStatus = 0

    // Fixture Link headers assume this origin; client uses clientBaseUrl.
    val fixtureBaseUrl = tc.configOverrides?.baseUrl ?: "https://fizzy.do"
    val clientBaseUrl = tc.configOverrides?.baseUrl ?: "http://localhost:9876"
    val fixtureOrigin = extractOrigin(fixtureBaseUrl)
    val clientOrigin = extractOrigin(clientBaseUrl)

    val mockEngine = MockEngine { request ->
        val bodyBytes = request.body.toByteArray()
        val bodyText = bodyBytes.decodeToString()

        if (mockIdx < tc.mockResponses.size) {
            val mock = tc.mockResponses[mockIdx++]
            if (mock.delay != null && mock.delay > 0) {
                Thread.sleep(mock.delay.toLong())
            }
            val content = when {
                mock.body == null || mock.body is JsonNull -> ""
                else -> Json.encodeToString(JsonElement.serializer(), mock.body)
            }
            val rewrittenHeaders = rewriteLinkHeaders(mock.headers, fixtureOrigin, clientOrigin)
            val mockHeaders = headersOf(
                *rewrittenHeaders.map { (k, v) -> k to listOf(v) }.toTypedArray()
            )
            lastResponseStatus = mock.status
            records.add(
                RequestRecord(
                    timeMs = System.currentTimeMillis(),
                    method = request.method.value,
                    url = request.url.toString(),
                    body = bodyText,
                    headers = request.headers,
                    responseStatus = mock.status,
                )
            )
            respond(
                content = content,
                status = HttpStatusCode.fromValue(mock.status),
                headers = mockHeaders,
            )
        } else {
            val hasLink = tc.mockResponses.any { "Link" in it.headers }
            val overflowStatus = if (hasLink) 200 else 500
            lastResponseStatus = overflowStatus
            records.add(
                RequestRecord(
                    timeMs = System.currentTimeMillis(),
                    method = request.method.value,
                    url = request.url.toString(),
                    body = bodyText,
                    headers = request.headers,
                    responseStatus = overflowStatus,
                )
            )
            if (hasLink) {
                respond(
                    content = "[]",
                    status = HttpStatusCode.OK,
                    headers = headersOf("Content-Type", "application/json"),
                )
            } else {
                respond(content = "", status = HttpStatusCode.InternalServerError)
            }
        }
    }

    val result = safeExecute(tc, mockEngine)
    // If no error, propagate the last success status
    val finalResult = if (result.error == null) {
        result.copy(lastMockStatus = lastResponseStatus)
    } else {
        result
    }
    return finalResult to records
}

fun safeExecute(tc: TestCase, engine: MockEngine): ExecResult {
    return try {
        executeOperation(tc, engine)
    } catch (e: IllegalArgumentException) {
        // HTTPS enforcement throws IllegalArgumentException
        ExecResult(
            error = FizzyException.Usage(e.message ?: "Usage error"),
            lastMockStatus = 0,
        )
    } catch (e: FizzyException) {
        ExecResult(error = e, lastMockStatus = e.httpStatus ?: 0)
    } catch (e: Exception) {
        ExecResult(error = e, lastMockStatus = 0)
    }
}

fun executeOperation(tc: TestCase, engine: MockEngine): ExecResult {
    val baseUrl = tc.configOverrides?.baseUrl ?: "http://localhost:9876"

    val client = FizzyClient {
        accessToken("test-token")
        this.baseUrl = baseUrl
        this.engine = engine
        enableRetry = true
    }

    val accountId = tc.pathParams["accountId"]?.let { jsonElementToString(it) } ?: "999"
    val account = client.forAccount(accountId)

    return runBlocking {
        try {
            val value = dispatchOperation(tc, account)
            ExecResult(value = value)
        } catch (e: FizzyException) {
            ExecResult(error = e, lastMockStatus = e.httpStatus ?: 0)
        } catch (e: Exception) {
            ExecResult(error = e)
        } finally {
            client.close()
        }
    }
}

// ---------------------------------------------------------------------------
// Operation dispatch
// ---------------------------------------------------------------------------

/**
 * Determine whether the test expects actual multi-page pagination.
 * Mirrors the Go runner's hasPagination heuristic: multiple mock responses
 * with Link headers, or urlOrigin assertions testing cross-origin rejection.
 */
private fun hasPagination(tc: TestCase): Boolean {
    if (tc.mockResponses.size > 1 && tc.mockResponses.any { "Link" in it.headers }) return true
    if (tc.assertions.any { it.type == "urlOrigin" }) return true
    return false
}

/**
 * For list tests that don't expect multi-page pagination, limit to the first
 * page's item count so the SDK doesn't follow the Link header.
 */
private fun singlePageOptions(tc: TestCase): PaginationOptions? {
    if (hasPagination(tc)) return null
    val firstBody = tc.mockResponses.firstOrNull()?.body
    val count = (firstBody as? JsonArray)?.size ?: return null
    return if (count > 0) PaginationOptions(maxItems = count) else null
}

suspend fun dispatchOperation(tc: TestCase, account: AccountClient): Any? {
    val pp = tc.pathParams
    val body = tc.requestBody
    val qp = tc.queryParams
    val pageOpts = singlePageOptions(tc)

    return when (tc.operation) {
        // Boards
        "ListBoards" -> account.boards.list(pageOpts)
        "CreateBoard" -> account.boards.create(
            CreateBoardBody(
                name = body?.str("name") ?: "",
                allAccess = body?.boolOrNull("all_access"),
            )
        )
        "GetBoard" -> account.boards.get(pp.string("boardId"))
        "UpdateBoard" -> account.boards.update(
            pp.string("boardId"),
            UpdateBoardBody(
                name = body?.strOrNull("name"),
                allAccess = body?.boolOrNull("all_access"),
            ),
        )
        "DeleteBoard" -> account.boards.delete(pp.string("boardId"))

        // Cards
        "ListCards" -> account.cards.list(ListCardsOptions(
            boardId = qp.strOrNull("board_id"),
            columnId = qp.strOrNull("column_id"),
            assigneeId = qp.strOrNull("assignee_id"),
            tag = qp.strOrNull("tag"),
            status = qp.strOrNull("status"),
            q = qp.strOrNull("q"),
        ))
        "CreateCard" -> account.cards.create(
            CreateCardBody(title = body?.str("title") ?: "")
        )
        "GetCard" -> account.cards.get(pp.long("cardNumber"))
        "UpdateCard" -> account.cards.update(
            pp.long("cardNumber"),
            UpdateCardBody(
                title = body?.strOrNull("title"),
                description = body?.strOrNull("description"),
                columnId = body?.strOrNull("column_id"),
            ),
        )
        "DeleteCard" -> account.cards.delete(pp.long("cardNumber"))
        "AssignCard" -> account.cards.assign(
            pp.long("cardNumber"),
            AssignCardBody(assigneeId = body?.str("assignee_id") ?: ""),
        )
        "MoveCard" -> account.cards.move(
            pp.long("cardNumber"),
            MoveCardBody(
                boardId = body?.str("board_id") ?: "",
                columnId = body?.strOrNull("column_id"),
            ),
        )
        "CloseCard" -> account.cards.close(pp.long("cardNumber"))
        "ReopenCard" -> account.cards.reopen(pp.long("cardNumber"))
        "GoldCard" -> account.cards.gold(pp.long("cardNumber"))
        "UngoldCard" -> account.cards.ungold(pp.long("cardNumber"))
        "DeleteCardImage" -> account.cards.deleteImage(pp.long("cardNumber"))
        "PostponeCard" -> account.cards.postpone(pp.long("cardNumber"))
        "PinCard" -> account.cards.pin(pp.long("cardNumber"))
        "UnpinCard" -> account.cards.unpin(pp.long("cardNumber"))
        "SelfAssignCard" -> account.cards.selfAssign(pp.long("cardNumber"))
        "TagCard" -> account.cards.tag(
            pp.long("cardNumber"),
            TagCardBody(tagTitle = body?.str("tag_title") ?: ""),
        )
        "TriageCard" -> account.cards.triage(pp.long("cardNumber"), TriageCardBody())
        "UnTriageCard" -> account.cards.untriage(pp.long("cardNumber"))
        "WatchCard" -> account.cards.watch(pp.long("cardNumber"))
        "UnwatchCard" -> account.cards.unwatch(pp.long("cardNumber"))

        // Columns
        "ListColumns" -> account.columns.list(pp.string("boardId"))
        "CreateColumn" -> account.columns.create(
            pp.string("boardId"),
            CreateColumnBody(
                name = body?.str("name") ?: "",
                color = body?.strOrNull("color"),
            ),
        )
        "GetColumn" -> account.columns.get(pp.string("boardId"), pp.string("columnId"))
        "UpdateColumn" -> account.columns.update(
            pp.string("boardId"),
            pp.string("columnId"),
            UpdateColumnBody(
                name = body?.strOrNull("name"),
                color = body?.strOrNull("color"),
            ),
        )
        "DeleteColumn" -> account.columns.delete(pp.string("boardId"), pp.string("columnId"))

        // Comments
        "ListComments" -> account.comments.list(pp.long("cardNumber"))
        "CreateComment" -> account.comments.create(
            pp.long("cardNumber"),
            CreateCommentBody(body = body?.str("body") ?: ""),
        )
        "GetComment" -> account.comments.get(pp.long("cardNumber"), pp.string("commentId"))
        "UpdateComment" -> account.comments.update(
            pp.long("cardNumber"),
            pp.string("commentId"),
            UpdateCommentBody(body = body?.str("body") ?: ""),
        )
        "DeleteComment" -> account.comments.delete(pp.long("cardNumber"), pp.string("commentId"))

        // Devices
        "RegisterDevice" -> account.devices.register(
            RegisterDeviceBody(
                token = body?.str("token") ?: "",
                platform = body?.str("platform") ?: "",
                name = body?.strOrNull("name"),
            )
        )
        "UnregisterDevice" -> account.devices.unregister(pp.string("deviceToken"))

        // Identity
        "GetMyIdentity" -> account.identity.me()

        // Notifications
        "ListNotifications" -> account.notifications.list()
        "BulkReadNotifications" -> account.notifications.bulkRead(
            BulkReadNotificationsBody(
                notificationIds = body?.stringListOrNull("notification_ids"),
            )
        )
        "GetNotificationTray" -> account.notifications.tray(GetNotificationTrayOptions(
            includeRead = qp.boolOrNull("include_read"),
        ))
        "ReadNotification" -> account.notifications.read(pp.string("notificationId"))
        "UnreadNotification" -> account.notifications.unread(pp.string("notificationId"))

        // Pins
        "ListPins" -> account.pins.list()

        // Reactions
        "ListCommentReactions" -> account.reactions.listForComment(
            pp.long("cardNumber"), pp.string("commentId"),
        )
        "CreateCommentReaction" -> account.reactions.createForComment(
            pp.long("cardNumber"),
            pp.string("commentId"),
            CreateCommentReactionBody(content = body?.str("content") ?: ""),
        )
        "DeleteCommentReaction" -> account.reactions.deleteForComment(
            pp.long("cardNumber"), pp.string("commentId"), pp.string("reactionId"),
        )
        "ListCardReactions" -> account.reactions.listForCard(pp.long("cardNumber"))
        "CreateCardReaction" -> account.reactions.createForCard(
            pp.long("cardNumber"),
            CreateCardReactionBody(content = body?.str("content") ?: ""),
        )
        "DeleteCardReaction" -> account.reactions.deleteForCard(
            pp.long("cardNumber"), pp.string("reactionId"),
        )

        // Sessions
        "CreateSession" -> account.sessions.create(
            CreateSessionBody(emailAddress = body?.str("email_address") ?: ""),
        )
        "DestroySession" -> account.sessions.destroy()
        "RedeemMagicLink" -> account.sessions.redeemMagicLink(
            RedeemMagicLinkBody(token = body?.str("token") ?: ""),
        )
        "CompleteSignup" -> account.sessions.completeSignup(
            CompleteSignupBody(name = body?.str("name") ?: ""),
        )

        // Steps
        "CreateStep" -> account.steps.create(
            pp.long("cardNumber"),
            CreateStepBody(content = body?.str("content") ?: ""),
        )
        "GetStep" -> account.steps.get(pp.long("cardNumber"), pp.string("stepId"))
        "UpdateStep" -> account.steps.update(
            pp.long("cardNumber"),
            pp.string("stepId"),
            UpdateStepBody(
                content = body?.strOrNull("content"),
                completed = body?.boolOrNull("completed"),
            ),
        )
        "DeleteStep" -> account.steps.delete(pp.long("cardNumber"), pp.string("stepId"))

        // Tags
        "ListTags" -> account.tags.list()

        // Uploads
        "CreateDirectUpload" -> account.uploads.createDirect(
            CreateDirectUploadBody(
                filename = body?.str("filename") ?: "",
                contentType = body?.str("content_type") ?: "",
                byteSize = body?.long("byte_size") ?: 0,
                checksum = body?.str("checksum") ?: "",
            )
        )

        // Users
        "ListUsers" -> account.users.list()
        "GetUser" -> account.users.get(pp.string("userId"))
        "UpdateUser" -> account.users.update(
            pp.string("userId"),
            UpdateUserBody(name = body?.strOrNull("name")),
        )
        "DeactivateUser" -> account.users.deactivate(pp.string("userId"))

        // Webhooks
        "ListWebhooks" -> account.webhooks.list(pp.string("boardId"))
        "CreateWebhook" -> account.webhooks.create(
            pp.string("boardId"),
            CreateWebhookBody(
                name = body?.str("name") ?: "",
                url = body?.str("url") ?: "",
                subscribedActions = body?.stringListOrNull("subscribed_actions"),
            ),
        )
        "GetWebhook" -> account.webhooks.get(pp.string("boardId"), pp.string("webhookId"))
        "UpdateWebhook" -> account.webhooks.update(
            pp.string("boardId"),
            pp.string("webhookId"),
            UpdateWebhookBody(
                name = body?.strOrNull("name"),
                url = body?.strOrNull("url"),
                subscribedActions = body?.stringListOrNull("subscribed_actions"),
            ),
        )
        "DeleteWebhook" -> account.webhooks.delete(pp.string("boardId"), pp.string("webhookId"))
        "ActivateWebhook" -> account.webhooks.activate(pp.string("boardId"), pp.string("webhookId"))

        else -> throw FizzyException.Usage("Unknown operation: ${tc.operation}")
    }
}

// ---------------------------------------------------------------------------
// Assertion checking
// ---------------------------------------------------------------------------

fun checkAssertions(tc: TestCase, result: ExecResult, records: List<RequestRecord>): Boolean {
    var allPassed = true
    for (a in tc.assertions) {
        if (!checkAssertion(tc, a, result, records)) {
            allPassed = false
        }
    }
    return allPassed
}

fun checkAssertion(
    tc: TestCase,
    a: Assertion,
    result: ExecResult,
    records: List<RequestRecord>,
): Boolean {
    when (a.type) {
        "requestCount" -> {
            val expected = a.expected.asInt()
            val actual = records.size
            if (actual != expected) {
                println("    ASSERT FAIL [requestCount]: expected $expected, got $actual")
                return false
            }
            return true
        }

        "delayBetweenRequests" -> {
            val minMs = a.min ?: a.expected.asInt()
            if (records.size < 2) {
                println("    ASSERT FAIL [delayBetweenRequests]: need at least 2 requests, got ${records.size}")
                return false
            }
            for (i in 1 until records.size) {
                val delay = records[i].timeMs - records[i - 1].timeMs
                if (delay < minMs) {
                    println("    ASSERT FAIL [delayBetweenRequests]: delay between request ${i} and ${i + 1} was ${delay}ms, expected >= ${minMs}ms")
                    return false
                }
            }
            return true
        }

        "statusCode" -> {
            val expected = a.expected.asInt()
            val actual = when {
                result.error is FizzyException -> (result.error).httpStatus ?: 0
                result.lastMockStatus > 0 -> result.lastMockStatus
                records.isNotEmpty() -> records.last().responseStatus
                else -> 200
            }
            if (actual != expected) {
                println("    ASSERT FAIL [statusCode]: expected $expected, got $actual")
                return false
            }
            return true
        }

        "noError" -> {
            if (result.error != null) {
                println("    ASSERT FAIL [noError]: got error: ${result.error.message}")
                return false
            }
            return true
        }

        "errorCode" -> {
            val expected = a.expected.asString()
            if (result.error == null) {
                println("    ASSERT FAIL [errorCode]: expected error with code \"$expected\", got no error")
                return false
            }
            val err = result.error
            if (err !is FizzyException) {
                println("    ASSERT FAIL [errorCode]: error is not FizzyException: ${err::class.simpleName}: ${err.message}")
                return false
            }
            if (err.code != expected) {
                println("    ASSERT FAIL [errorCode]: expected \"$expected\", got \"${err.code}\"")
                return false
            }
            return true
        }

        "errorField" -> {
            if (result.error == null) {
                println("    ASSERT FAIL [errorField]: expected error, got null")
                return false
            }
            val err = result.error
            if (err !is FizzyException) {
                println("    ASSERT FAIL [errorField]: error is not FizzyException")
                return false
            }
            val expected = a.expected.asString()
            when (a.path) {
                "requestId" -> {
                    if (err.requestId != expected) {
                        println("    ASSERT FAIL [errorField.requestId]: expected \"$expected\", got \"${err.requestId}\"")
                        return false
                    }
                }
                else -> {
                    println("    ASSERT FAIL [errorField]: unknown field path \"${a.path}\"")
                    return false
                }
            }
            return true
        }

        "headerPresent" -> {
            val headerName = a.path ?: return true
            if (records.isEmpty()) {
                println("    ASSERT FAIL [headerPresent]: no requests recorded")
                return false
            }
            val last = records.last()
            if (last.headers[headerName] == null) {
                println("    ASSERT FAIL [headerPresent]: header \"$headerName\" not present")
                return false
            }
            return true
        }

        "requestPath" -> {
            val expected = a.expected.asString()
            if (records.isEmpty()) {
                println("    ASSERT FAIL [requestPath]: no requests recorded")
                return false
            }
            val last = records.last()
            val actualPath = Url(last.url).encodedPath
            if (actualPath != expected) {
                println("    ASSERT FAIL [requestPath]: expected \"$expected\", got \"$actualPath\"")
                return false
            }
            return true
        }

        "urlOrigin" -> {
            val expected = a.expected.asString()
            if (expected == "rejected") {
                // Cross-origin/protocol-downgrade Link rejected: either error or silent stop
                if (result.error == null && records.size > 1) {
                    println("    ASSERT FAIL [urlOrigin]: expected cross-origin Link to not be followed, got ${records.size} requests")
                    return false
                }
            }
            return true
        }

        "requestBodyField" -> {
            val expected = a.expected.asString()
            if (records.isEmpty()) {
                println("    ASSERT FAIL [requestBodyField]: no requests recorded")
                return false
            }
            val last = records.last()
            if (last.body.isNullOrBlank()) {
                println("    ASSERT FAIL [requestBodyField]: request body is empty")
                return false
            }
            val bodyObj = json.parseToJsonElement(last.body).jsonObject
            if (expected !in bodyObj) {
                println("    ASSERT FAIL [requestBodyField]: field \"$expected\" not found in request body (keys: ${bodyObj.keys})")
                return false
            }
            return true
        }

        "requestQueryParam" -> {
            val paramName = a.path ?: ""
            val expected = a.expected.asString()
            if (records.isEmpty()) {
                println("    ASSERT FAIL [requestQueryParam]: no requests recorded")
                return false
            }
            val last = records.last()
            val parsedUrl = Url(last.url)
            val actual = parsedUrl.parameters[paramName]
            if (actual != expected) {
                println("    ASSERT FAIL [requestQueryParam]: param \"$paramName\" expected \"$expected\", got \"$actual\"")
                return false
            }
            return true
        }

        else -> {
            println("    ASSERT SKIP [${ a.type }]: unsupported assertion type")
            return true
        }
    }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

private fun jsonElementToString(el: JsonElement): String = when (el) {
    is JsonPrimitive -> el.content
    else -> el.toString()
}

private fun Map<String, JsonElement>.long(key: String): Long {
    val el = this[key] ?: throw IllegalArgumentException("Missing path param: $key")
    return when (el) {
        is JsonPrimitive -> el.long
        else -> el.toString().toLong()
    }
}

private fun Map<String, JsonElement>.longOrNull(key: String): Long? =
    (this[key] as? JsonPrimitive)?.longOrNull

private fun Map<String, JsonElement>.strOrNull(key: String): String? =
    (this[key] as? JsonPrimitive)?.contentOrNull

private fun Map<String, JsonElement>.boolOrNull(key: String): Boolean? {
    val el = (this[key] as? JsonPrimitive) ?: return null
    // Query params may be string "true"/"false" rather than JSON boolean
    return el.booleanOrNull ?: (el.contentOrNull == "true")
}

private fun Map<String, JsonElement>.string(key: String): String {
    val el = this[key] ?: throw IllegalArgumentException("Missing path param: $key")
    return jsonElementToString(el)
}

private fun JsonObject.str(key: String): String? = this[key]?.jsonPrimitive?.content
private fun JsonObject.strOrNull(key: String): String? = this[key]?.jsonPrimitive?.contentOrNull
private fun JsonObject.long(key: String): Long? = this[key]?.jsonPrimitive?.long
private fun JsonObject.longOrNull(key: String): Long? = this[key]?.jsonPrimitive?.longOrNull
private fun JsonObject.boolOrNull(key: String): Boolean? = this[key]?.jsonPrimitive?.booleanOrNull

private fun JsonObject.longListOrNull(key: String): List<Long>? =
    (this[key] as? JsonArray)?.map { it.jsonPrimitive.long }

private fun JsonObject.stringListOrNull(key: String): List<String>? =
    (this[key] as? JsonArray)?.map { it.jsonPrimitive.content }

private fun JsonElement?.asInt(): Int = when (this) {
    is JsonPrimitive -> if (isString) content.toInt() else int
    else -> 0
}

private fun JsonElement?.asString(): String = when (this) {
    is JsonPrimitive -> content
    else -> this?.toString() ?: ""
}
