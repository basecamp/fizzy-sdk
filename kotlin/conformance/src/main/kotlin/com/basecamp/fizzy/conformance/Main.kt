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

fun runTest(tc: TestCase): Pair<ExecResult, List<RequestRecord>> {
    val records = mutableListOf<RequestRecord>()
    var mockIdx = 0
    var lastResponseStatus = 0

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
            val mockHeaders = headersOf(
                *mock.headers.map { (k, v) -> k to listOf(v) }.toTypedArray()
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

suspend fun dispatchOperation(tc: TestCase, account: AccountClient): Any? {
    val pp = tc.pathParams
    val body = tc.requestBody

    return when (tc.operation) {
        // Boards
        "ListBoards" -> account.boards.list()
        "CreateBoard" -> account.boards.create(
            CreateBoardBody(
                name = body?.str("name") ?: "",
                allAccess = body?.boolOrNull("all_access"),
            )
        )
        "GetBoard" -> account.boards.get(pp.long("boardId"))
        "UpdateBoard" -> account.boards.update(
            pp.long("boardId"),
            UpdateBoardBody(
                name = body?.strOrNull("name"),
                allAccess = body?.boolOrNull("all_access"),
            ),
        )
        "DeleteBoard" -> account.boards.delete(pp.long("boardId"))

        // Cards
        "ListCards" -> account.cards.list()
        "CreateCard" -> account.cards.create(
            CreateCardBody(title = body?.str("title") ?: "")
        )
        "GetCard" -> account.cards.get(pp.long("cardNumber"))
        "UpdateCard" -> account.cards.update(
            pp.long("cardNumber"),
            UpdateCardBody(
                title = body?.strOrNull("title"),
                description = body?.strOrNull("description"),
                columnId = body?.longOrNull("column_id"),
            ),
        )
        "DeleteCard" -> account.cards.delete(pp.long("cardNumber"))
        "AssignCard" -> account.cards.assign(
            pp.long("cardNumber"),
            AssignCardBody(userId = body?.long("user_id") ?: 0),
        )
        "MoveCard" -> account.cards.move(
            pp.long("cardNumber"),
            MoveCardBody(
                boardId = body?.long("board_id") ?: 0,
                columnId = body?.longOrNull("column_id"),
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
            TagCardBody(name = body?.str("name") ?: ""),
        )
        "TriageCard" -> account.cards.triage(pp.long("cardNumber"))
        "UnTriageCard" -> account.cards.untriage(pp.long("cardNumber"))
        "WatchCard" -> account.cards.watch(pp.long("cardNumber"))
        "UnwatchCard" -> account.cards.unwatch(pp.long("cardNumber"))

        // Columns
        "ListColumns" -> account.columns.list(pp.long("boardId"))
        "CreateColumn" -> account.columns.create(
            pp.long("boardId"),
            CreateColumnBody(
                name = body?.str("name") ?: "",
                color = body?.strOrNull("color"),
            ),
        )
        "GetColumn" -> account.columns.get(pp.long("boardId"), pp.long("columnId"))
        "UpdateColumn" -> account.columns.update(
            pp.long("boardId"),
            pp.long("columnId"),
            UpdateColumnBody(
                name = body?.strOrNull("name"),
                color = body?.strOrNull("color"),
            ),
        )

        // Comments
        "ListComments" -> account.comments.list(pp.long("cardNumber"))
        "CreateComment" -> account.comments.create(
            pp.long("cardNumber"),
            CreateCommentBody(body = body?.str("body") ?: ""),
        )
        "GetComment" -> account.comments.get(pp.long("cardNumber"), pp.long("commentId"))
        "UpdateComment" -> account.comments.update(
            pp.long("cardNumber"),
            pp.long("commentId"),
            UpdateCommentBody(body = body?.str("body") ?: ""),
        )
        "DeleteComment" -> account.comments.delete(pp.long("cardNumber"), pp.long("commentId"))

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
                notificationIds = body?.longListOrNull("notification_ids"),
            )
        )
        "GetNotificationTray" -> account.notifications.tray()
        "ReadNotification" -> account.notifications.read(pp.long("notificationId"))
        "UnreadNotification" -> account.notifications.unread(pp.long("notificationId"))

        // Pins
        "ListPins" -> account.pins.list()

        // Reactions
        "ListCommentReactions" -> account.reactions.listForComment(
            pp.long("cardNumber"), pp.long("commentId"),
        )
        "CreateCommentReaction" -> account.reactions.createForComment(
            pp.long("cardNumber"),
            pp.long("commentId"),
            CreateCommentReactionBody(content = body?.str("content") ?: ""),
        )
        "DeleteCommentReaction" -> account.reactions.deleteForComment(
            pp.long("cardNumber"), pp.long("commentId"), pp.long("reactionId"),
        )
        "ListCardReactions" -> account.reactions.listForCard(pp.long("cardNumber"))
        "CreateCardReaction" -> account.reactions.createForCard(
            pp.long("cardNumber"),
            CreateCardReactionBody(content = body?.str("content") ?: ""),
        )
        "DeleteCardReaction" -> account.reactions.deleteForCard(
            pp.long("cardNumber"), pp.long("reactionId"),
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
        "GetStep" -> account.steps.get(pp.long("cardNumber"), pp.long("stepId"))
        "UpdateStep" -> account.steps.update(
            pp.long("cardNumber"),
            pp.long("stepId"),
            UpdateStepBody(
                content = body?.strOrNull("content"),
                completed = body?.boolOrNull("completed"),
            ),
        )
        "DeleteStep" -> account.steps.delete(pp.long("cardNumber"), pp.long("stepId"))

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
        "GetUser" -> account.users.get(pp.long("userId"))
        "UpdateUser" -> account.users.update(
            pp.long("userId"),
            UpdateUserBody(name = body?.strOrNull("name")),
        )
        "DeactivateUser" -> account.users.deactivate(pp.long("userId"))

        // Webhooks
        "ListWebhooks" -> account.webhooks.list(pp.long("boardId"))
        "CreateWebhook" -> account.webhooks.create(
            pp.long("boardId"),
            CreateWebhookBody(
                name = body?.str("name") ?: "",
                url = body?.str("url") ?: "",
                subscribedActions = body?.stringListOrNull("subscribed_actions"),
            ),
        )
        "GetWebhook" -> account.webhooks.get(pp.long("boardId"), pp.long("webhookId"))
        "UpdateWebhook" -> account.webhooks.update(
            pp.long("boardId"),
            pp.long("webhookId"),
            UpdateWebhookBody(
                name = body?.strOrNull("name"),
                url = body?.strOrNull("url"),
                subscribedActions = body?.stringListOrNull("subscribed_actions"),
            ),
        )
        "DeleteWebhook" -> account.webhooks.delete(pp.long("boardId"), pp.long("webhookId"))
        "ActivateWebhook" -> account.webhooks.activate(pp.long("boardId"), pp.long("webhookId"))

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
