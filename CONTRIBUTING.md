# Contributing to Fizzy SDK

## Prerequisites

- Smithy CLI
- Go 1.26+
- Node.js 20+
- Ruby 3.2+
- Swift 6.0+
- JDK 17+
- Rust 1.88+ (the MSRV; `rust/rust-toolchain.toml` pins the dev toolchain, and `cargo deny` is needed for `make rs-check`)
- Make
- [mise](https://mise.jdx.dev/) (recommended)

## Environment Setup

This repo uses [mise](https://mise.jdx.dev/) to pin tool versions (see `.mise.toml`). Activate it in your shell to avoid silently picking up a different Go from Homebrew or system PATH:

```sh
eval "$(mise activate bash)"   # or: mise activate zsh
```

Alternatively, prefix commands with `mise exec --`.

## Development Workflow

1. Fork and clone the repository
2. Create a feature branch: `git checkout -b my-feature`
3. Make changes following the patterns in AGENTS.md
4. Run checks: `make check`
5. Commit and push
6. Open a pull request

## Adding a New API Operation

1. Add the operation to the Smithy spec in `spec/`
2. Run `make smithy-build` to regenerate OpenAPI
3. Run `make {lang}-generate-services` for each language
4. Add unit tests
5. Add conformance tests if the operation has behavioral requirements
6. Run `make check`

## Conformance Suite

`conformance/tests/*.json` holds the language-agnostic behaviour fixtures (retry, pagination,
error mapping, request shapes, ...), validated by `conformance/schema.json`. Each SDK has a
runner that drives every case through its own client against a scripted transport, so a
behavioural claim is pinned in all six languages at once:

| Runner | Location | Run |
|--------|----------|-----|
| Go | `conformance/runner/go` | `make conformance-go` |
| TypeScript | `conformance/runner/typescript` | `make conformance-typescript` |
| Ruby | `conformance/runner/ruby` | `make conformance-ruby` |
| Swift | `conformance/runner/swift` | `make conformance-swift` (needs a Swift toolchain; CI runs it on macOS) |
| Kotlin | `kotlin/conformance` | `make conformance-kotlin` |
| Rust | `conformance/runner/rust` | `make conformance-rust` |

`make conformance` runs all six. The Swift and Rust runners carry unit tests for their own
assertion helpers (`make conformance-runner-tests-swift`, `make conformance-runner-tests-rust`),
which the conformance targets run first.

## Syncing to Upstream Fizzy

The SDK generators read the Smithy spec, but the Smithy spec should be maintained against upstream Fizzy API sources:

- [`docs/api/README.md`](https://github.com/basecamp/fizzy/blob/main/docs/api/README.md)
- [`docs/api/sections/`](https://github.com/basecamp/fizzy/tree/main/docs/api/sections)
- [`config/routes.rb`](https://github.com/basecamp/fizzy/blob/main/config/routes.rb)
- [`app/controllers/`](https://github.com/basecamp/fizzy/tree/main/app/controllers)
- [`app/views/`](https://github.com/basecamp/fizzy/tree/main/app/views)
- [`app/models/`](https://github.com/basecamp/fizzy/tree/main/app/models)

Recommended sync workflow:

1. Review upstream docs and Rails changes
2. Update `spec/fizzy.smithy` / `spec/fizzy-traits.smithy`
3. Run `make smithy-build`
4. Run language generators
5. Update tests
6. Update `spec/api-provenance.json`
7. Run `make provenance-sync`
8. Run `make check`

## Release Process

Releases are managed via `make release VERSION=x.y.z`. See the Makefile for details.

### Publishing the Rust crate for the first time

`release-rust.yml` publishes `fizzy-sdk` to crates.io through [trusted
publishing](https://crates.io/docs/trusted-publishing), which can only be configured on a
crate that already exists. The first version is therefore published by hand, once, from
the exact commit about to be tagged:

1. On `main`, with a clean tree and `HEAD == origin/main`, run `make check` — the same
   preflight `make release` runs, so the bytes published by hand are the bytes the tag
   will point at.
2. Mint a [crates.io API token](https://crates.io/settings/tokens/new) scoped
   `publish-new` and `change-owners`, crate-name pattern `fizzy-sdk`, one-day expiry.
3. Hand the token to Cargo for the next two commands without writing it to disk:
   `export CARGO_REGISTRY_TOKEN=<token>`.
4. `cd rust && cargo publish -p fizzy-sdk --locked`
5. `cargo owner --add github:basecamp:cli fizzy-sdk`, then `unset CARGO_REGISTRY_TOKEN`.
6. On the crate's settings page, add a Trusted Publisher: repository owner `basecamp`,
   repository `fizzy-sdk`, workflow `release-rust.yml` (the exact basename; a rename breaks
   the token exchange), environment `release-crates`.
7. Revoke the token.
8. In the repository settings, create the `release-crates` environment, restrict it to tag
   refs matching `v*`, and add required reviewers.
9. `make release VERSION=x.y.z` from the same commit. The workflow finds the version
   already published with a matching checksum and skips the upload; every later release
   publishes through OIDC with no token anywhere.
