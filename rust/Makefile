# Fizzy Rust SDK Makefile

CARGO := cargo

.PHONY: all
all: check

# Regenerate rust/fizzy-sdk/src/generated from openapi.json and behavior-model.json
.PHONY: generate
generate:
	@echo "Generating Rust types, routes and services from openapi.json..."
	$(CARGO) run -q -p fizzy-sdk-generator

# Fail when the checked-in generated code differs from what the generator emits
.PHONY: generate-check
generate-check:
	$(CARGO) run -q -p fizzy-sdk-generator -- --check

.PHONY: build
build:
	$(CARGO) build --locked

.PHONY: fmt
fmt:
	$(CARGO) fmt --all

.PHONY: fmt-check
fmt-check:
	$(CARGO) fmt --all -- --check

.PHONY: lint
lint: fmt-check
	$(CARGO) clippy --workspace --all-targets --all-features --locked -- -D warnings

.PHONY: test
test:
	$(CARGO) test --workspace --all-features --locked

# Broken intra-doc links fail the build
.PHONY: doc
doc:
	RUSTDOCFLAGS="-D warnings" $(CARGO) doc -p fizzy-sdk --no-deps --all-features

.PHONY: deny
deny:
	$(CARGO) deny check

.PHONY: publish-check
publish-check:
	$(CARGO) publish -p fizzy-sdk --dry-run --locked

# Run all checks (local development gate)
.PHONY: check
check: lint test doc deny generate-check publish-check

.PHONY: clean
clean:
	$(CARGO) clean

.PHONY: help
help:
	@echo "Fizzy Rust SDK Makefile targets:"
	@echo ""
	@echo "  generate        Regenerate src/generated from openapi.json"
	@echo "  generate-check  Verify src/generated is up to date"
	@echo "  build           Build the workspace"
	@echo "  fmt             Format code"
	@echo "  fmt-check       Check formatting"
	@echo "  lint            fmt-check + clippy with warnings denied"
	@echo "  test            Run all tests"
	@echo "  doc             Build the crate docs"
	@echo "  deny            Run cargo deny"
	@echo "  publish-check   cargo publish --dry-run"
	@echo "  check           lint + test + doc + deny + generate-check + publish-check"
	@echo "  clean           Remove build artifacts"
