---
description: Sync the Fizzy SDK spec and generated SDKs to upstream Fizzy API changes
user_invocable: true
---

# Fizzy SDK Upstream Sync Workflow

Sync this repo to upstream Fizzy API changes.

## Purpose

This repo does **not** bump a third-party SDK dependency.
Instead, the upstream sync workflow is:

1. review upstream Fizzy API changes
2. update the Smithy spec in `spec/`
3. regenerate derived artifacts and per-language SDK code
4. add/update tests
5. update provenance
6. run full checks

## Hard Rules

- **Never hand-write API methods.** All operations must come from the Smithy spec.
- **Never construct URL paths manually.** Use the generated route table.
- **Never edit `openapi.json` directly.** It is derived from Smithy.
- **Every new operation needs tests.** Add unit tests per language plus conformance tests.
- **Run `make check` before finishing.**

## Canonical Upstream Sources

When syncing, treat these upstream Fizzy sources as the references:

- `docs/api/README.md`
- `docs/api/sections/`
- `config/routes.rb`
- `app/controllers/`
- `app/views/`
- `app/models/`

If docs and behavior disagree, verify against routes/controllers/views/models and then update Smithy to match actual behavior.

## Steps

1. **Read the current baseline**
   - Read `spec/api-provenance.json`
   - Read `spec/README.md`
   - Read `AGENTS.md`

2. **Check what changed upstream**
   - Run `make sync-status`
   - If needed, inspect the changed upstream files in the Fizzy app repo at the recorded revision vs `main`
   - Focus only on API-relevant changes in the canonical sources listed above

3. **Update the Smithy spec**
   - Edit `spec/fizzy.smithy`
   - Edit `spec/fizzy-traits.smithy` if new traits or modeling support are required
   - Keep changes additive and shape-accurate
   - Do not patch generated SDK code by hand to compensate for missing Smithy changes

4. **Regenerate derived artifacts**
   - Run `make smithy-build`
   - Run `make url-routes`

5. **Regenerate SDKs**
   Run the generators needed for the impacted languages. For a normal API sync, run all of them:

   - `make go-generate-services`
   - `make ts-generate`
   - `make ts-generate-services`
   - `make rb-generate`
   - `make rb-generate-services`
   - `make swift-generate`
   - `make kt-generate-services`

6. **Add or update tests**
   - Add unit tests for each affected language
   - Add/update conformance tests for behavioral changes
   - If a new operation was added, make sure tests cover request/response behavior and any special semantics

7. **Update provenance**
   - Update `spec/api-provenance.json` with the new upstream revision/date
   - Keep the tracked `paths` aligned with the canonical upstream sources
   - Run `make provenance-sync`

8. **Run validation**
   - Run `make check`
   - Fix any drift, generation, or test failures before finishing

9. **Summarize the upstream sync**
   Include:
   - old vs new upstream revision
   - which upstream API surfaces changed
   - which Smithy operations/shapes changed
   - which SDKs/tests were regenerated or updated

## Expected Outputs

A complete sync should typically leave changes in areas like:

- `spec/fizzy.smithy`
- `spec/fizzy-traits.smithy` (if needed)
- `openapi.json`
- `behavior-model.json`
- `url-routes.json`
- generated SDK service/type files in language directories
- tests
- `spec/api-provenance.json`
- `go/pkg/fizzy/api-provenance.json`

## Stop Conditions

Stop and call out the issue if:

- the upstream behavior is ambiguous across docs/routes/controllers/views/models
- a change would require hand-written API methods instead of Smithy-driven generation
- generated route data is missing and would force manual path building
- a new behavior cannot be covered by tests
