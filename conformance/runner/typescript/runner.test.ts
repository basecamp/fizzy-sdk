import { describe, it, expect, afterAll, afterEach, beforeAll } from "vitest";
import { readdirSync, readFileSync } from "fs";
import { join, basename } from "path";
import { fileURLToPath } from "url";
import { setupServer } from "msw/node";
import { http, HttpResponse } from "msw";
import {
  createFizzyClient,
  FizzyError,
  type FizzyClient,
} from "@37signals/fizzy";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface MockResponse {
  status: number;
  headers?: Record<string, string>;
  body: unknown;
}

interface Assertion {
  type: string;
  expected?: unknown;
  path?: string;
  min?: number;
}

interface TestCase {
  name: string;
  description?: string;
  operation: string;
  method: string;
  path: string;
  pathParams?: Record<string, unknown>;
  requestBody?: Record<string, unknown>;
  queryParams?: Record<string, string>;
  configOverrides?: Record<string, unknown>;
  mockResponses: MockResponse[];
  assertions: Assertion[];
  tags?: string[];
}

// ---------------------------------------------------------------------------
// Request log
// ---------------------------------------------------------------------------

interface RequestLog {
  count: number;
  times: number[];
  lastRequest: Request | null;
  bodies: (Record<string, unknown> | null)[];
  paths: string[];
}

function freshLog(): RequestLog {
  return { count: 0, times: [], lastRequest: null, bodies: [], paths: [] };
}

// ---------------------------------------------------------------------------
// Retry-enabled test suites
// ---------------------------------------------------------------------------

const RETRY_ENABLED_FILES = new Set(["retry.json", "idempotency.json", "error-mapping.json", "status-codes.json"]);

function shouldEnableRetry(filename: string): boolean {
  return RETRY_ENABLED_FILES.has(filename);
}

// ---------------------------------------------------------------------------
// Test file loading
// ---------------------------------------------------------------------------

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const testsDir = join(__dirname, "../../tests");
const testFiles = readdirSync(testsDir)
  .filter((f) => f.endsWith(".json"))
  .sort();

// ---------------------------------------------------------------------------
// MSW server
// ---------------------------------------------------------------------------

const server = setupServer();
beforeAll(() => server.listen({ onUnhandledRequest: "bypass" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

// ---------------------------------------------------------------------------
// Operation dispatcher
// ---------------------------------------------------------------------------

function stringArray(value: unknown): string[] | undefined {
  if (Array.isArray(value)) return value.map(String);
  if (value === undefined || value === null || value === "") return undefined;
  return [String(value)];
}

async function dispatch(
  client: FizzyClient,
  tc: TestCase,
): Promise<{ data?: unknown; response?: Response; error?: FizzyError }> {
  const p = tc.pathParams ?? {};
  const body = tc.requestBody ?? {};

  try {
    let data: unknown;

    switch (tc.operation) {
      // Boards
      case "ListBoards":
        data = await (client as any).boards.list();
        break;
      case "CreateBoard":
        data = await (client as any).boards.create(body);
        break;
      case "GetBoard":
        data = await (client as any).boards.get(p.boardId as number);
        break;
      case "ListBoardAccesses": {
        const qb = tc.queryParams ?? {};
        data = await (client as any).boards.listBoardAccesses(String(p.boardId), {
          page: qb.page ? Number(qb.page) : undefined,
        });
        break;
      }
      case "UpdateBoard":
        data = await (client as any).boards.update(p.boardId as number, body);
        break;
      case "DeleteBoard":
        data = await (client as any).boards.delete(p.boardId as number);
        break;
      case "PublishBoard":
        data = await (client as any).boards.publishBoard(p.boardId as number);
        break;
      case "UnpublishBoard":
        data = await (client as any).boards.unpublishBoard(p.boardId as number);
        break;

      // Cards
      case "ListCards": {
        const qc = tc.queryParams ?? {};
        data = await (client as any).cards.list({
          boardIds: stringArray(qc["board_ids[]"]),
          tagIds: stringArray(qc["tag_ids[]"]),
          assigneeIds: stringArray(qc["assignee_ids[]"]),
          creatorIds: stringArray(qc["creator_ids[]"]),
          closerIds: stringArray(qc["closer_ids[]"]),
          cardIds: stringArray(qc["card_ids[]"]),
          indexedBy: qc.indexed_by as string | undefined,
          sortedBy: qc.sorted_by as string | undefined,
          assignmentStatus: qc.assignment_status as string | undefined,
          creation: qc.creation as string | undefined,
          closure: qc.closure as string | undefined,
          terms: stringArray(qc["terms[]"]),
        });
        break;
      }
      case "CreateCard":
        data = await (client as any).cards.create(body);
        break;
      case "GetCard":
        data = await (client as any).cards.get(p.cardNumber as number);
        break;
      case "UpdateCard":
        data = await (client as any).cards.update(p.cardNumber as number, body);
        break;
      case "DeleteCard":
        data = await (client as any).cards.delete(p.cardNumber as number);
        break;
      case "AssignCard":
        data = await (client as any).cards.assign(p.cardNumber as number, { assigneeId: body.assignee_id });
        break;
      case "MoveCard":
        data = await (client as any).cards.move(p.cardNumber as number, { boardId: body.board_id as number, columnId: body.column_id as number | undefined });
        break;
      case "CloseCard":
        data = await (client as any).cards.close(p.cardNumber as number);
        break;
      case "ReopenCard":
        data = await (client as any).cards.reopen(p.cardNumber as number);
        break;
      case "TagCard":
        data = await (client as any).cards.tag(p.cardNumber as number, { tagTitle: body.tag_title });
        break;
      case "ListStreamCards":
        data = await (client as any).cards.listStreamCards(p.boardId as number);
        break;
      case "ListPostponedCards":
        data = await (client as any).cards.listPostponedCards(p.boardId as number);
        break;
      case "ListClosedCards":
        data = await (client as any).cards.listClosedCards(p.boardId as number);
        break;
      case "PublishCard":
        data = await (client as any).cards.publishCard(p.cardNumber as number);
        break;
      case "SearchCards": {
        const qs = tc.queryParams ?? {};
        data = await (client as any).cards.searchCards({ q: qs.q });
        break;
      }
      case "ListActivities": {
        const qa = tc.queryParams ?? {};
        data = await (client as any).cards.listActivities({
          creatorIds: stringArray(qa["creator_ids[]"]),
          boardIds: stringArray(qa["board_ids[]"]),
        });
        break;
      }
      case "ListColumnCards":
        data = await (client as any).cards.listColumnCards(p.boardId as number, p.columnId as number);
        break;

      // Comments
      case "ListComments":
        data = await (client as any).comments.list(p.cardNumber as number);
        break;
      case "CreateComment":
        data = await (client as any).comments.create(p.cardNumber as number, body);
        break;
      case "GetComment":
        data = await (client as any).comments.get(p.cardNumber as number, p.commentId as number);
        break;
      case "UpdateComment":
        data = await (client as any).comments.update(p.cardNumber as number, p.commentId as number, body);
        break;
      case "DeleteComment":
        data = await (client as any).comments.delete(p.cardNumber as number, p.commentId as number);
        break;

      // Reactions
      case "ListCardReactions":
        data = await (client as any).reactions.listForCard(p.cardNumber as number);
        break;
      case "CreateCardReaction":
        data = await (client as any).reactions.createForCard(p.cardNumber as number, { content: body.content });
        break;
      case "DeleteCardReaction":
        data = await (client as any).reactions.deleteForCard(p.cardNumber as number, p.reactionId as number);
        break;
      case "ListCommentReactions":
        data = await (client as any).reactions.listForComment(p.cardNumber as number, p.commentId as number);
        break;
      case "CreateCommentReaction":
        data = await (client as any).reactions.createForComment(p.cardNumber as number, p.commentId as number, { content: body.content });
        break;
      case "DeleteCommentReaction":
        data = await (client as any).reactions.deleteForComment(p.cardNumber as number, p.commentId as number, p.reactionId as number);
        break;

      // Steps
      case "ListSteps":
        data = await (client as any).steps.list(p.cardNumber as number);
        break;
      case "CreateStep":
        data = await (client as any).steps.create(p.cardNumber as number, { content: body.content });
        break;
      case "GetStep":
        data = await (client as any).steps.get(p.cardNumber as number, p.stepId as number);
        break;
      case "UpdateStep":
        data = await (client as any).steps.update(p.cardNumber as number, p.stepId as number, body);
        break;
      case "DeleteStep":
        data = await (client as any).steps.delete(p.cardNumber as number, p.stepId as number);
        break;

      // Columns
      case "ListColumns":
        data = await (client as any).columns.list(p.boardId as number);
        break;
      case "CreateColumn":
        data = await (client as any).columns.create(p.boardId as number, body);
        break;
      case "GetColumn":
        data = await (client as any).columns.get(p.boardId as number, p.columnId as number);
        break;
      case "UpdateColumn":
        data = await (client as any).columns.update(p.boardId as number, p.columnId as number, body);
        break;
      case "DeleteColumn":
        data = await (client as any).columns.delete(p.boardId as number, p.columnId as number);
        break;

      // Webhooks
      case "ListWebhooks":
        data = await (client as any).webhooks.list(p.boardId as number);
        break;
      case "CreateWebhook":
        data = await (client as any).webhooks.create(p.boardId as number, body);
        break;
      case "GetWebhook":
        data = await (client as any).webhooks.get(p.boardId as number, p.webhookId as number);
        break;
      case "UpdateWebhook":
        data = await (client as any).webhooks.update(p.boardId as number, p.webhookId as number, body);
        break;
      case "DeleteWebhook":
        data = await (client as any).webhooks.delete(p.boardId as number, p.webhookId as number);
        break;
      case "ActivateWebhook":
        data = await (client as any).webhooks.activate(p.boardId as number, p.webhookId as number);
        break;
      case "ListWebhookDeliveries":
        data = await (client as any).webhooks.listWebhookDeliveries(String(p.boardId), String(p.webhookId));
        break;

      // Sessions
      case "CreateSession":
        data = await (client as any).sessions.create({ emailAddress: body.email_address });
        break;
      case "DestroySession":
        data = await (client as any).sessions.destroy();
        break;
      case "RedeemMagicLink":
        data = await (client as any).sessions.redeemMagicLink({ token: body.token });
        break;
      case "CompleteSignup":
        data = await (client as any).sessions.completeSignup({ full_name: body.full_name });
        break;
      case "CompleteJoin":
        data = await (client as any).sessions.completeJoin({ name: body.name });
        break;

      // Identity
      case "GetMyIdentity":
        data = await (client as any).identity.me();
        break;

      // Notifications
      case "ListNotifications": {
        const qn = tc.queryParams ?? {};
        data = await (client as any).notifications.list({
          read: qn.read === "true" ? true : qn.read === "false" ? false : undefined,
        });
        break;
      }
      case "GetNotificationTray": {
        const qt = tc.queryParams ?? {};
        data = await (client as any).notifications.tray({
          includeRead: qt.include_read === "true" ? true : qt.include_read === "false" ? false : undefined,
        });
        break;
      }
      case "BulkReadNotifications":
        data = await (client as any).notifications.bulkRead({ notificationIds: body.notification_ids as number[] });
        break;
      case "ReadNotification":
        data = await (client as any).notifications.read(p.notificationId as number);
        break;
      case "UnreadNotification":
        data = await (client as any).notifications.unread(p.notificationId as number);
        break;

      // Users
      case "ListUsers":
        data = await (client as any).users.list();
        break;
      case "GetUser":
        data = await (client as any).users.get(String(p.userId));
        break;
      case "UpdateUser":
        data = await (client as any).users.update(String(p.userId), body);
        break;
      case "DeactivateUser":
        data = await (client as any).users.deactivate(String(p.userId));
        break;
      case "RequestEmailAddressChange":
        data = await (client as any).users.requestEmailAddressChange(String(p.userId), { emailAddress: body.email_address });
        break;
      case "ConfirmEmailAddressChange":
        data = await (client as any).users.confirmEmailAddressChange(String(p.userId), String(p.emailAddressToken));
        break;
      case "CreateUserDataExport":
        data = await (client as any).users.createUserDataExport(String(p.userId));
        break;
      case "GetUserDataExport":
        data = await (client as any).users.userDataExport(String(p.userId), String(p.exportId));
        break;

      // Pins
      case "ListPins":
        data = await (client as any).pins.list();
        break;

      // Devices
      case "RegisterDevice":
        data = await (client as any).devices.register({ token: body.token as string, platform: body.platform as string });
        break;
      case "UnregisterDevice":
        data = await (client as any).devices.unregister(p.deviceToken as string);
        break;

      // Uploads
      case "CreateDirectUpload":
        data = await (client as any).uploads.createDirect({
          filename: body.filename as string,
          contentType: body.content_type as string,
          byteSize: body.byte_size as number,
          checksum: body.checksum as string,
        });
        break;

      // Miscellaneous — Access Tokens
      case "ListAccessTokens":
        data = await (client as any).miscellaneous.listAccessTokens();
        break;
      case "CreateAccessToken":
        data = await (client as any).miscellaneous.createAccessToken({ description: body.description, permission: body.permission });
        break;
      case "DeleteAccessToken":
        data = await (client as any).miscellaneous.deleteAccessToken(p.accessTokenId as string);
        break;

      // Miscellaneous — Account
      case "UpdateAccountEntropy":
        data = await (client as any).miscellaneous.updateAccountEntropy({ autoPostponePeriodInDays: body.auto_postpone_period_in_days });
        break;
      case "CreateAccountExport":
        data = await (client as any).miscellaneous.createAccountExport();
        break;
      case "GetAccountExport":
        data = await (client as any).miscellaneous.accountExport(p.exportId as string);
        break;
      case "GetJoinCode":
        data = await (client as any).miscellaneous.joinCode();
        break;
      case "UpdateJoinCode":
        data = await (client as any).miscellaneous.updateJoinCode({ usageLimit: body.usage_limit });
        break;
      case "ResetJoinCode":
        data = await (client as any).miscellaneous.resetJoinCode();
        break;
      case "GetAccountSettings":
        data = await (client as any).miscellaneous.accountSettings();
        break;
      case "UpdateAccountSettings":
        data = await (client as any).miscellaneous.updateAccountSettings({ name: body.name });
        break;

      // Miscellaneous — Board extras
      case "UpdateBoardEntropy":
        data = await (client as any).miscellaneous.updateBoardEntropy(p.boardId as number, { autoPostponePeriodInDays: body.auto_postpone_period_in_days });
        break;
      case "UpdateBoardInvolvement":
        data = await (client as any).miscellaneous.updateBoardInvolvement(p.boardId as number, { involvement: body.involvement });
        break;

      // Miscellaneous — Card read/unread
      case "MarkCardRead":
        data = await (client as any).miscellaneous.markCardRead(p.cardNumber as number);
        break;
      case "MarkCardUnread":
        data = await (client as any).miscellaneous.markCardUnread(p.cardNumber as number);
        break;

      // Miscellaneous — Column movement
      case "MoveColumnLeft":
        data = await (client as any).miscellaneous.moveColumnLeft(p.columnId as number);
        break;
      case "MoveColumnRight":
        data = await (client as any).miscellaneous.moveColumnRight(p.columnId as number);
        break;

      // Miscellaneous — Notification settings
      case "GetNotificationSettings":
        data = await (client as any).miscellaneous.notificationSettings();
        break;
      case "UpdateNotificationSettings":
        data = await (client as any).miscellaneous.updateNotificationSettings({ bundleEmailFrequency: body.bundle_email_frequency });
        break;

      // Miscellaneous — User extras
      case "DeleteUserAvatar":
        data = await (client as any).miscellaneous.deleteUserAvatar(p.userId as string);
        break;
      case "CreatePushSubscription":
        data = await (client as any).miscellaneous.createPushSubscription(p.userId as string, { endpoint: body.endpoint, p256dhKey: body.p256dh_key, authKey: body.auth_key });
        break;
      case "DeletePushSubscription":
        data = await (client as any).miscellaneous.deletePushSubscription(p.userId as string, p.pushSubscriptionId as string);
        break;
      case "UpdateUserRole":
        data = await (client as any).miscellaneous.updateUserRole(p.userId as string, { role: body.role });
        break;

      default:
        throw new Error(`Unknown operation: ${tc.operation}`);
    }

    return { data };
  } catch (err) {
    if (err instanceof FizzyError) {
      return { error: err };
    }
    throw err;
  }
}

// ---------------------------------------------------------------------------
// Test runner
// ---------------------------------------------------------------------------

for (const file of testFiles) {
  const suiteName = basename(file, ".json");
  const cases: TestCase[] = JSON.parse(
    readFileSync(join(testsDir, file), "utf-8"),
    // Preserve integers beyond MAX_SAFE_INTEGER as strings (Node 22+ reviver with source text)
    function (_key: string, value: unknown) {
      const ctx = arguments[2] as { source?: string } | undefined;
      if (typeof value === "number" && ctx?.source && !Number.isSafeInteger(value) && /^-?\d+$/.test(ctx.source)) {
        return ctx.source;
      }
      return value;
    },
  );
  const filename = basename(file);

  describe(suiteName, () => {
    for (const tc of cases) {
      it(tc.name, async () => {
        const log = freshLog();
        let mockIdx = 0;

        // Determine base URL
        const configOverrides = tc.configOverrides ?? {};
        const baseUrl = (configOverrides.baseUrl as string) ?? "http://localhost:9876";

        // Check for HTTPS enforcement test (non-localhost HTTP URL)
        const hasUsageErrorAssertion = tc.assertions.some(
          (a) => a.type === "errorCode" && a.expected === "usage",
        );
        const hasZeroRequestAssertion = tc.assertions.some(
          (a) => a.type === "requestCount" && a.expected === 0,
        );

        if (hasUsageErrorAssertion && hasZeroRequestAssertion) {
          // This test expects client creation to fail
          try {
            createFizzyClient({
              accessToken: "test-token",
              baseUrl,
              enableRetry: false,
            });
            // If client creation didn't throw, try dispatching
            expect.unreachable("Expected FizzyError with code 'usage'");
          } catch (err) {
            expect(err).toBeInstanceOf(FizzyError);
            const fizzyErr = err as FizzyError;
            for (const assertion of tc.assertions) {
              checkAssertion(assertion, log, undefined, fizzyErr, undefined);
            }
          }
          return;
        }

        // Set up MSW handler
        server.use(
          http.all(`${baseUrl}/*`, async ({ request }) => {
            log.count++;
            log.times.push(Date.now());
            log.lastRequest = request.clone();
            log.paths.push(new URL(request.url).pathname);

            // Parse body
            try {
              const text = await request.clone().text();
              if (text) {
                log.bodies.push(JSON.parse(text));
              } else {
                log.bodies.push(null);
              }
            } catch {
              log.bodies.push(null);
            }

            if (mockIdx < tc.mockResponses.length) {
              const mock = tc.mockResponses[mockIdx++]!;
              const headers = new Headers(mock.headers ?? {});
              const responseBody =
                mock.body !== null && mock.body !== undefined
                  ? JSON.stringify(mock.body)
                  : null;
              return new HttpResponse(responseBody, {
                status: mock.status,
                headers,
              });
            }

            // Overflow: for pagination tests return empty array, otherwise 500
            const hasLink = tc.mockResponses.some(
              (m) => m.headers?.Link,
            );
            if (hasLink) {
              return HttpResponse.json([], { status: 200 });
            }
            return new HttpResponse(null, { status: 500 });
          }),
        );

        // Also handle requests to the base URL root (for non-account-scoped paths like /session.json)
        server.use(
          http.all(baseUrl, async ({ request }) => {
            log.count++;
            log.times.push(Date.now());
            log.lastRequest = request.clone();
            log.paths.push(new URL(request.url).pathname);

            try {
              const text = await request.clone().text();
              if (text) {
                log.bodies.push(JSON.parse(text));
              } else {
                log.bodies.push(null);
              }
            } catch {
              log.bodies.push(null);
            }

            if (mockIdx < tc.mockResponses.length) {
              const mock = tc.mockResponses[mockIdx++]!;
              const headers = new Headers(mock.headers ?? {});
              const responseBody =
                mock.body !== null && mock.body !== undefined
                  ? JSON.stringify(mock.body)
                  : null;
              return new HttpResponse(responseBody, {
                status: mock.status,
                headers,
              });
            }
            return new HttpResponse(null, { status: 500 });
          }),
        );

        // Create client
        const accountId = tc.pathParams?.accountId as string | undefined;
        const client = createFizzyClient({
          accessToken: "test-token",
          baseUrl: accountId ? `${baseUrl}/${accountId}` : baseUrl,
          enableRetry: shouldEnableRetry(filename),
        });

        // Dispatch operation
        const { data, error } = await dispatch(client, tc);

        // Check assertions
        for (const assertion of tc.assertions) {
          checkAssertion(assertion, log, data, error, tc);
        }
      });
    }
  });
}

// ---------------------------------------------------------------------------
// Assertion checker
// ---------------------------------------------------------------------------

function checkAssertion(
  assertion: Assertion,
  log: RequestLog,
  data: unknown,
  error: FizzyError | undefined,
  tc: TestCase | undefined,
): void {
  switch (assertion.type) {
    case "requestCount":
      expect(log.count, `requestCount: expected ${assertion.expected}, got ${log.count}`).toBe(
        assertion.expected,
      );
      break;

    case "delayBetweenRequests": {
      const min = assertion.min!;
      for (let i = 1; i < log.times.length; i++) {
        const delta = log.times[i]! - log.times[i - 1]!;
        expect(delta, `delayBetweenRequests: gap ${i} was ${delta}ms, expected >= ${min}ms`).toBeGreaterThanOrEqual(
          min,
        );
      }
      break;
    }

    case "statusCode": {
      const expected = assertion.expected as number;
      if (error) {
        expect(error.httpStatus, `statusCode from error`).toBe(expected);
      } else {
        // Success — status was 2xx
        expect(expected >= 200 && expected < 300, `statusCode: got success but expected ${expected}`).toBe(true);
      }
      break;
    }

    case "noError":
      expect(error, `noError: expected no error but got ${error?.code}: ${error?.message}`).toBeUndefined();
      break;

    case "errorCode":
      expect(error, `errorCode: expected error with code '${assertion.expected}' but no error was thrown`).toBeDefined();
      expect(error!.code, `errorCode`).toBe(assertion.expected);
      break;

    case "errorField": {
      expect(error, `errorField: expected error`).toBeDefined();
      const fieldPath = assertion.path!;
      const actual = (error as any)[fieldPath];
      expect(actual, `errorField ${fieldPath}`).toBe(assertion.expected);
      break;
    }

    case "errorMessage":
      expect(error, `errorMessage: expected error`).toBeDefined();
      expect(error!.message).toContain(assertion.expected as string);
      break;

    case "headerPresent": {
      expect(log.lastRequest, `headerPresent: no request captured`).not.toBeNull();
      const headerName = assertion.path!;
      expect(
        log.lastRequest!.headers.has(headerName),
        `headerPresent: expected header '${headerName}'`,
      ).toBe(true);
      break;
    }

    case "headerValue": {
      expect(log.lastRequest, `headerValue: no request captured`).not.toBeNull();
      const headerName = assertion.path!;
      expect(log.lastRequest!.headers.get(headerName), `headerValue: ${headerName}`).toBe(
        assertion.expected as string,
      );
      break;
    }

    case "requestPath": {
      const expectedPath = assertion.expected as string;
      expect(log.paths.length, `requestPath: no requests captured`).toBeGreaterThan(0);
      // Check the first request path (the initial API call)
      expect(log.paths[0], `requestPath`).toBe(expectedPath);
      break;
    }

    case "urlOrigin": {
      if (assertion.expected === "rejected") {
        // Cross-origin or protocol-downgrade Link was not followed.
        // Either the SDK threw an error or silently stopped paginating — both are valid.
        if (!error) {
          expect(log.count, `urlOrigin rejected: cross-origin Link should not be followed`).toBe(1);
        }
      }
      break;
    }

    case "responseMeta": {
      expect(data, `responseMeta: expected data`).toBeDefined();
      break;
    }

    case "responseBody": {
      expect(data, `responseBody: expected data`).toBeDefined();
      expect(data).toEqual(assertion.expected);
      break;
    }

    case "headerInjected": {
      expect(log.lastRequest, `headerInjected: no request captured`).not.toBeNull();
      break;
    }

    case "requestScheme": {
      expect(log.lastRequest, `requestScheme: no request captured`).not.toBeNull();
      const url = new URL(log.lastRequest!.url);
      expect(url.protocol).toBe(`${assertion.expected as string}:`);
      break;
    }

    case "requestBodyField": {
      const fieldName = assertion.expected as string;
      const lastBody = log.bodies.find((b) => b !== null);
      expect(lastBody, `requestBodyField: no request body captured`).toBeDefined();
      expect(
        fieldName in lastBody!,
        `requestBodyField: expected field '${fieldName}' in body ${JSON.stringify(lastBody)}`,
      ).toBe(true);
      break;
    }

    case "requestQueryParam": {
      expect(log.lastRequest, `requestQueryParam: no request captured`).not.toBeNull();
      const url = new URL(log.lastRequest!.url);
      const paramName = assertion.path!;
      const expected = String(assertion.expected);
      expect(
        url.searchParams.get(paramName),
        `requestQueryParam: expected ${paramName}=${expected}`,
      ).toBe(expected);
      break;
    }

    default:
      throw new Error(`Unknown assertion type: ${assertion.type}`);
  }
}
