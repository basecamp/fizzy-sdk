# Fizzy SDK -- Agent Instructions

Multi-language client for the Fizzy API (Go, TypeScript, Ruby, Swift, Kotlin), generated
from the Smithy spec in `spec/`.

## Hard Rules

1. **Never hand-write API methods.** All operations are generated from the Smithy spec.
2. **Never construct URL paths manually.** Use the generated route table -- no
   `fmt.Sprintf` or template literals for paths.
3. **Every new operation needs tests.** Unit tests per language + conformance tests.
4. **Run `make check` before committing.**

Never edit `openapi.json` by hand; it is generated from Smithy and the drift checks in
`make check` will fail when it disagrees with the spec.

## Pipeline

```
spec/fizzy.smithy -> openapi.json -> behavior-model.json -> per-language generators
```

## Development Workflow

1. Check the upstream sources below -- the spec is downstream of them
2. Edit the Smithy spec in `spec/`
3. `make smithy-build` to regenerate OpenAPI
4. Regenerate **every** language, not just the one you were working in.
   `make smithy-build` rewrites the shared `openapi.json`, so all five generated
   service layers go stale at once, and `make check` runs a drift check for each of
   them. This repo has no aggregate `generate-services` target, so name them
   individually:

   ```bash
   make go-generate-services
   make ts-generate-services
   make rb-generate-services
   make kt-generate-services
   make swift-generate
   ```
5. Add or update tests
6. `make check`

## Upstream Reference Sources

The SDK pipeline starts from Smithy, but Smithy is kept aligned with upstream Fizzy.
When syncing the spec, treat these as primary:

- **API docs** — [`docs/api/README.md`](https://github.com/basecamp/fizzy/blob/main/docs/api/README.md)
- **API section docs** — [`docs/api/sections/`](https://github.com/basecamp/fizzy/tree/main/docs/api/sections)
- **Routes** — [`config/routes.rb`](https://github.com/basecamp/fizzy/blob/main/config/routes.rb)
- **Controllers** — [`app/controllers/`](https://github.com/basecamp/fizzy/tree/main/app/controllers)
- **Views / JSON rendering** — [`app/views/`](https://github.com/basecamp/fizzy/tree/main/app/views)
- **Relevant models** — [`app/models/`](https://github.com/basecamp/fizzy/tree/main/app/models)

## Auth Model

Fizzy uses **two auth strategies, and no OAuth**:

- **BearerAuth** — `Authorization: Bearer <token>` for CLI/API access tokens
- **CookieAuth** — `Cookie: session_token=<value>` for session-based auth (mobile/web)

**MagicLinkFlow** orchestrates passwordless login: `CreateSession` → `RedeemMagicLink`.

## API Surface

`spec/fizzy.smithy` is the inventory. Read it, or `grep -c '^operation ' spec/fizzy.smithy`
for the count -- do not keep a second copy of the operation list here.
