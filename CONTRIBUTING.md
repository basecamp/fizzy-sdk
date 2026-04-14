# Contributing to Fizzy SDK

## Prerequisites

- Smithy CLI
- Go 1.26+
- Node.js 20+
- Ruby 3.2+
- Swift 6.0+
- JDK 17+
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
