# Fizzy Rust SDK Makefile

CARGO := cargo
RUNNER := ../conformance/runner/rust

.PHONY: all
all: check

# Regenerate fizzy-sdk/src/generated from openapi.json and behavior-model.json
.PHONY: generate
generate:
	$(CARGO) run -q -p fizzy-sdk-generator

# Fail when the checked-in generated code differs from what the generator emits
.PHONY: generate-check
generate-check:
	$(CARGO) run -q -p fizzy-sdk-generator -- --check

.PHONY: build
build:
	$(CARGO) build --workspace --locked

.PHONY: fmt
fmt:
	$(CARGO) fmt --all
	$(CARGO) fmt --all --manifest-path $(RUNNER)/Cargo.toml

.PHONY: fmt-check
fmt-check:
	$(CARGO) fmt --all -- --check
	$(CARGO) fmt --all --manifest-path $(RUNNER)/Cargo.toml -- --check

.PHONY: clippy
clippy:
	$(CARGO) clippy --workspace --all-targets --all-features --locked -- -D warnings
	$(CARGO) clippy --manifest-path $(RUNNER)/Cargo.toml --all-targets --locked -- -D warnings

.PHONY: lint
lint: fmt-check clippy

# Both workspaces, all features: the SDK, its generator and the conformance runner
.PHONY: test
test:
	$(CARGO) test --workspace --all-features --locked
	$(CARGO) test --manifest-path $(RUNNER)/Cargo.toml --locked

# The library alone, as the MSRV leg builds it
.PHONY: test-lib
test-lib:
	$(CARGO) test -p fizzy-sdk --all-features --locked

# The other feature sets the crate promises: no default features, and the examples.
# Without the reqwest feature there is no shipped HTTP client, so the leg runs the unit
# tests and proves every target still compiles; the integration tests and doctests
# exercise the shipped client under --all-features in `test`.
.PHONY: test-features
test-features:
	$(CARGO) test -p fizzy-sdk --no-default-features --locked --lib
	$(CARGO) check -p fizzy-sdk --no-default-features --all-targets --locked
	$(CARGO) build -p fizzy-sdk --examples --all-features --locked

# Broken intra-doc links and missing docs fail the build
.PHONY: doc
doc:
	RUSTDOCFLAGS="-D warnings" $(CARGO) doc -p fizzy-sdk --no-deps --all-features --locked

# Advisories, licenses, bans and sources for both workspaces under one deny.toml
.PHONY: deny
deny:
	$(CARGO) deny --manifest-path Cargo.toml check
	$(CARGO) deny --manifest-path $(RUNNER)/Cargo.toml --config deny.toml check

# Metadata, include list and path dependencies, checked before a tag exists
.PHONY: publish-check
publish-check:
	$(CARGO) publish -p fizzy-sdk --dry-run --locked

# Run all checks (local development gate)
.PHONY: check
check: lint test test-features doc deny generate-check publish-check

.PHONY: clean
clean:
	$(CARGO) clean
	$(CARGO) clean --manifest-path $(RUNNER)/Cargo.toml

.PHONY: help
help:
	@echo "Fizzy Rust SDK Makefile targets:"
	@echo ""
	@echo "  generate        Regenerate src/generated from openapi.json"
	@echo "  generate-check  Verify src/generated is up to date"
	@echo "  build           Build the workspace"
	@echo "  fmt             Format both workspaces"
	@echo "  fmt-check       Check formatting"
	@echo "  clippy          Run clippy with warnings denied"
	@echo "  lint            fmt-check + clippy"
	@echo "  test            Run all tests (SDK, generator, conformance runner)"
	@echo "  test-lib        Run the SDK tests alone (the MSRV leg)"
	@echo "  test-features   Test with no default features; build the examples"
	@echo "  doc             Build the crate docs"
	@echo "  deny            cargo deny check for both workspaces"
	@echo "  publish-check   cargo publish --dry-run"
	@echo "  check           lint + test + test-features + doc + deny + generate-check + publish-check"
	@echo "  clean           Remove build artifacts"
