import { describe, it, expect, beforeAll, afterAll, afterEach } from "vitest";
import { setupServer } from "msw/node";
import { http, HttpResponse } from "msw";
import { MagicLinkFlow, isFizzyError } from "../src/index.js";

// Fizzy's contract (SessionsController, Sessions::MagicLinksController, Signups::CompletionsController):
// POST /session.json {email_address} → 201 {pending_authentication_token};
// POST /session/magic_link.json {code} with Cookie: pending_authentication_token → 200
// {session_token, requires_signup_completion}; POST /signup/completion.json {full_name}
// under the session cookie → 201, no body.

const BASE_URL = "http://localhost:9878";
const server = setupServer();
beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

interface Seen {
  path: string;
  body: unknown;
  cookie: string | null;
}

function fizzy(seen: Seen[], redeem: { status: number; body: unknown } = {
  status: 200,
  body: { session_token: "st/1=", requires_signup_completion: false },
}) {
  const record = async (request: Request) => {
    const text = await request.text();
    seen.push({
      path: new URL(request.url).pathname,
      body: text ? JSON.parse(text) : undefined,
      cookie: request.headers.get("Cookie"),
    });
  };
  server.use(
    http.post(`${BASE_URL}/session.json`, async ({ request }) => {
      await record(request);
      return HttpResponse.json({ pending_authentication_token: "pend+1/=" }, { status: 201 });
    }),
    http.post(`${BASE_URL}/session/magic_link.json`, async ({ request }) => {
      await record(request);
      return HttpResponse.json(redeem.body, { status: redeem.status });
    }),
    http.post(`${BASE_URL}/signup/completion.json`, async ({ request }) => {
      await record(request);
      return new HttpResponse(null, { status: 201 });
    }),
  );
}

describe("MagicLinkFlow", () => {
  it("creates the session, keeps the pending token, and redeems the code with it as a cookie", async () => {
    const seen: Seen[] = [];
    fizzy(seen);
    const flow = new MagicLinkFlow({ baseUrl: BASE_URL });

    const created = await flow.createSession("ada@example.com");
    expect(created.pendingAuthenticationToken).toBe("pend+1/=");
    expect(flow.pendingToken).toBe("pend+1/=");

    const redeemed = await flow.redeem("ABC123");
    expect(redeemed.sessionToken).toBe("st/1=");
    expect(redeemed.requiresSignupCompletion).toBe(false);
    expect(flow.pendingToken).toBeUndefined();
    await expect(flow.redeem("ABC123")).rejects.toMatchObject({ code: "usage" });

    expect(seen).toEqual([
      { path: "/session.json", body: { email_address: "ada@example.com" }, cookie: null },
      {
        path: "/session/magic_link.json",
        body: { code: "ABC123" },
        cookie: "pending_authentication_token=pend%2B1%2F%3D",
      },
    ]);
  });

  it("answers an auth strategy that sends the session cookie", async () => {
    fizzy([]);
    const flow = MagicLinkFlow.resume("pend", { baseUrl: BASE_URL });
    const { auth } = await flow.redeem("ABC123");

    const headers = new Headers();
    await auth.authenticate(headers);
    expect(headers.get("Cookie")).toBe("session_token=st%2F1%3D");
  });

  it("resumes a sign-in another process started", async () => {
    const seen: Seen[] = [];
    fizzy(seen);
    const flow = MagicLinkFlow.resume("pend-elsewhere", { baseUrl: BASE_URL });

    await flow.redeem("ABC123");
    expect(seen).toEqual([
      { path: "/session/magic_link.json", body: { code: "ABC123" }, cookie: "pending_authentication_token=pend-elsewhere" },
    ]);
  });

  it("refuses to redeem with no sign-in pending, sending nothing", async () => {
    const seen: Seen[] = [];
    fizzy(seen);
    const flow = new MagicLinkFlow({ baseUrl: BASE_URL });

    await expect(flow.redeem("ABC123")).rejects.toMatchObject({ code: "usage" });
    expect(seen).toEqual([]);
  });

  it("maps a refused code to an auth error", async () => {
    fizzy([], { status: 401, body: { message: "Try another code." } });
    const flow = MagicLinkFlow.resume("pend", { baseUrl: BASE_URL });

    const error = await flow.redeem("WRONG").catch((e: unknown) => e);
    expect(isFizzyError(error)).toBe(true);
    expect(error).toMatchObject({ code: "auth_required", httpStatus: 401 });
  });

  it("completes a new account's sign-up under the session cookie", async () => {
    const seen: Seen[] = [];
    fizzy(seen, { status: 200, body: { session_token: "st-new", requires_signup_completion: true } });
    const flow = MagicLinkFlow.resume("pend", { baseUrl: BASE_URL });

    const { requiresSignupCompletion } = await flow.redeem("ABC123");
    expect(requiresSignupCompletion).toBe(true);
    await flow.completeSignup("Ada Lovelace");

    expect(seen[1]).toEqual({
      path: "/signup/completion.json",
      body: { full_name: "Ada Lovelace" },
      cookie: "session_token=st-new",
    });
  });

  it("refuses a plain-HTTP origin other than localhost", async () => {
    const flow = new MagicLinkFlow({ baseUrl: "http://fizzy.example.com" });
    await expect(flow.createSession("ada@example.com")).rejects.toMatchObject({ code: "usage" });
  });
});
