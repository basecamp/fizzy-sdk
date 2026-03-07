.PHONY: help check clean
.PHONY: smithy-validate smithy-mapper smithy-build smithy-check smithy-clean
.PHONY: behavior-model behavior-model-check
.PHONY: url-routes url-routes-check
.PHONY: sync-api-version sync-api-version-check
.PHONY: go-generate-services go-test go-lint go-check go-clean go-check-drift
.PHONY: ts-install ts-generate ts-generate-services ts-build ts-test ts-typecheck ts-check ts-check-drift ts-clean
.PHONY: rb-generate rb-generate-services rb-build rb-test rb-check rb-check-drift rb-clean
.PHONY: swift-build swift-test swift-check swift-check-drift swift-generate swift-clean
.PHONY: kt-generate-services kt-build kt-test kt-check kt-check-drift kt-clean
.PHONY: conformance-build conformance-go conformance-kotlin conformance-typescript conformance-ruby conformance
.PHONY: provenance-sync provenance-check sync-status
.PHONY: check-mvp check-full
.PHONY: bump release audit-check

# ──────────────────────────────────────────────
# Smithy
# ──────────────────────────────────────────────

MAVEN_ARTIFACT := $(HOME)/.m2/repository/com/basecamp/smithy-bare-arrays/1.0.0/smithy-bare-arrays-1.0.0.jar

smithy-mapper: ## Build vendored smithy-bare-arrays plugin to local Maven
	@if [ -f "$(MAVEN_ARTIFACT)" ]; then \
		echo "==> Smithy mapper plugin already in local Maven, skipping build"; \
	else \
		echo "==> Building Smithy mapper plugin..."; \
		cd spec/smithy-bare-arrays && ./gradlew publishToMavenLocal; \
	fi

smithy-validate: ## Validate Smithy model
	@echo "==> Validating Smithy model..."
	cd spec && smithy validate

smithy-build: smithy-mapper ## Build OpenAPI from Smithy
	@echo "==> Building OpenAPI spec..."
	cd spec && smithy build
	@cp spec/build/smithy/openapi/openapi/Fizzy.openapi.json openapi.json
	@echo "==> OpenAPI spec generated: openapi.json"

smithy-check: smithy-validate smithy-mapper ## Verify openapi.json is up to date
	@echo "==> Checking OpenAPI freshness..."
	@cd spec && smithy build
	@TMPFILE=$$(mktemp) && \
		cp spec/build/smithy/openapi/openapi/Fizzy.openapi.json "$$TMPFILE" && \
		(diff -q openapi.json "$$TMPFILE" > /dev/null 2>&1 || \
			(rm -f "$$TMPFILE" && echo "ERROR: openapi.json is out of date. Run 'make smithy-build'" && exit 1)) && \
		rm -f "$$TMPFILE"
	@echo "  openapi.json is fresh"

smithy-clean:
	rm -rf spec/build

# ──────────────────────────────────────────────
# Behavior Model
# ──────────────────────────────────────────────

behavior-model: ## Generate behavior-model.json from Smithy AST
	@echo "==> Generating behavior model..."
	./scripts/generate-behavior-model
	@echo "  behavior-model.json generated"

behavior-model-check: ## Verify behavior-model.json is up to date
	@echo "==> Checking behavior model freshness..."
	@TMPFILE=$$(mktemp) && \
		./scripts/generate-behavior-model "$$TMPFILE" && \
		(diff -q behavior-model.json "$$TMPFILE" > /dev/null 2>&1 || \
			(rm -f "$$TMPFILE" && echo "ERROR: behavior-model.json is stale. Run 'make behavior-model'" && exit 1)) && \
		rm -f "$$TMPFILE"
	@echo "  behavior-model.json is fresh"

# ──────────────────────────────────────────────
# URL Routes
# ──────────────────────────────────────────────

url-routes: ## Generate url-routes.json from OpenAPI
	@echo "==> Generating URL routes..."
	./scripts/generate-url-routes

url-routes-check:
	@echo "==> Checking URL routes freshness..."
	@TMPFILE=$$(mktemp) && \
		./scripts/generate-url-routes "$$TMPFILE" && \
		(diff -q go/pkg/fizzy/url-routes.json "$$TMPFILE" > /dev/null 2>&1 || \
			(rm -f "$$TMPFILE" && echo "ERROR: url-routes.json is stale. Run 'make url-routes'" && exit 1)) && \
		rm -f "$$TMPFILE"
	@echo "  url-routes.json is fresh"

# ──────────────────────────────────────────────
# API Version Sync
# ──────────────────────────────────────────────

sync-api-version: ## Sync API version from openapi.json to all SDKs
	@echo "==> Syncing API version..."
	./scripts/sync-api-version.sh

sync-api-version-check:
	@echo "==> Checking API version sync..."
	@API_VER=$$(jq -r '.info.version' openapi.json); \
	ok=true; \
	grep -q "APIVersion = \"$$API_VER\"" go/pkg/fizzy/version.go || ok=false; \
	grep -q "API_VERSION = \"$$API_VER\"" typescript/src/client.ts || ok=false; \
	grep -q "API_VERSION = \"$$API_VER\"" ruby/lib/fizzy/version.rb || ok=false; \
	grep -q "API_VERSION = \"$$API_VER\"" kotlin/sdk/src/commonMain/kotlin/com/basecamp/fizzy/FizzyConfig.kt || ok=false; \
	grep -q "apiVersion = \"$$API_VER\"" swift/Sources/Fizzy/FizzyConfig.swift || ok=false; \
	if [ "$$ok" = false ]; then echo "ERROR: API_VERSION constants out of sync. Run 'make sync-api-version'"; exit 1; fi
	@echo "  API version is in sync"

# ──────────────────────────────────────────────
# Provenance
# ──────────────────────────────────────────────

provenance-sync: ## Sync provenance file to Go SDK
	@echo "==> Syncing provenance..."
	@cp spec/api-provenance.json go/pkg/fizzy/api-provenance.json
	@echo "  Provenance synced"

provenance-check: ## Verify provenance file is in sync
	@echo "==> Checking provenance..."
	@diff -q spec/api-provenance.json go/pkg/fizzy/api-provenance.json > /dev/null 2>&1 || \
		(echo "ERROR: go/pkg/fizzy/api-provenance.json is out of date. Run 'make provenance-sync'" && exit 1)
	@echo "  Provenance is in sync"

sync-status: ## Show upstream changes since last sync
	@REV=$$(jq -r '.fizzy.revision' spec/api-provenance.json); \
	if [ -z "$$REV" ] || [ "$$REV" = "null" ] || [ "$$REV" = "" ]; then \
		echo "No revision recorded in api-provenance.json. Run provenance-sync after setting revision."; \
		exit 0; \
	fi; \
	echo "==> Checking for upstream changes since $$REV..."; \
	gh api "repos/basecamp/fizzy/compare/$$REV...main" --jq '.ahead_by' 2>/dev/null | xargs -I{} echo "  {} commits ahead" || \
		echo "  Could not query upstream (check gh auth)"

# ──────────────────────────────────────────────
# Go SDK
# ──────────────────────────────────────────────

go-generate-services: ## Generate Go service files from openapi.json
	@echo "==> Generating Go services..."
	cd go && go run ./cmd/generate-services/

go-test: ## Run Go tests
	@echo "==> Running Go tests..."
	cd go && go test ./pkg/fizzy/... -count=1 -race

go-lint:
	@echo "==> Linting Go..."
	cd go && golangci-lint run ./...

go-check-drift: ## Check Go service drift against generated client
	@echo "==> Checking Go service drift..."
	./scripts/check-service-drift.sh

go-check: go-test go-lint go-check-drift
	@echo "==> Go SDK checks passed"

go-clean:
	cd go && go clean -testcache

# ──────────────────────────────────────────────
# TypeScript SDK
# ──────────────────────────────────────────────

ts-install:
	@echo "==> Installing TypeScript dependencies..."
	cd typescript && npm ci

ts-generate: ts-install ## Generate TypeScript types from OpenAPI
	@echo "==> Generating TypeScript types..."
	cd typescript && npm run generate

ts-generate-services: ## Generate TypeScript service files
	@echo "==> Generating TypeScript services..."
	cd typescript && npx tsx scripts/generate-services.ts

ts-build: ts-install
	@echo "==> Building TypeScript SDK..."
	cd typescript && npm run build

ts-test: ts-install
	@echo "==> Running TypeScript tests..."
	cd typescript && npm test

ts-typecheck: ts-install
	@echo "==> Type-checking TypeScript..."
	cd typescript && npm run typecheck

ts-check-drift: ## Check TypeScript service drift
	@echo "==> Checking TypeScript service drift..."
	./scripts/check-ts-service-drift.sh

ts-check: ts-test ts-typecheck ts-check-drift
	@echo "==> TypeScript SDK checks passed"

ts-clean:
	rm -rf typescript/dist typescript/node_modules typescript/coverage

# ──────────────────────────────────────────────
# Ruby SDK
# ──────────────────────────────────────────────

rb-generate-services: ## Generate Ruby service files
	@echo "==> Generating Ruby services..."
	cd ruby && ruby scripts/generate-services.rb

rb-build:
	@echo "==> Building Ruby gem..."
	cd ruby && bundle exec rake build

rb-test: ## Run Ruby tests
	@echo "==> Running Ruby tests..."
	cd ruby && bundle exec rake test

rb-check-drift: ## Check Ruby service drift
	@echo "==> Checking Ruby service drift..."
	./scripts/check-rb-service-drift.sh

rb-check: rb-test rb-check-drift
	@echo "==> Ruby SDK checks passed"

rb-clean:
	rm -rf ruby/pkg ruby/coverage ruby/doc

# ──────────────────────────────────────────────
# Swift SDK
# ──────────────────────────────────────────────

swift-build: ## Build Swift SDK
	@echo "==> Building Swift SDK..."
	cd swift && swift build

swift-test: ## Run Swift tests
	@echo "==> Running Swift tests..."
	cd swift && swift test

swift-generate: ## Generate Swift services
	@echo "==> Generating Swift services..."
	cd swift && swift run FizzyGenerator --openapi ../openapi.json --behavior ../behavior-model.json --output Sources/Fizzy/Generated

swift-check-drift: ## Check Swift service drift
	@echo "==> Checking Swift service drift..."
	./scripts/check-swift-service-drift.sh

swift-check: swift-build swift-test swift-check-drift
	@echo "==> Swift SDK checks passed"

swift-clean:
	cd swift && swift package clean

# ──────────────────────────────────────────────
# Kotlin SDK
# ──────────────────────────────────────────────

kt-generate-services: ## Generate Kotlin services
	@echo "==> Generating Kotlin services..."
	cd kotlin && ./gradlew :generator:run

kt-build: ## Build Kotlin SDK
	@echo "==> Building Kotlin SDK..."
	cd kotlin && ./gradlew :fizzy-sdk:compileKotlinJvm

kt-test: ## Run Kotlin tests
	@echo "==> Running Kotlin tests..."
	cd kotlin && ./gradlew :fizzy-sdk:jvmTest

kt-check-drift:
	@echo "==> Checking Kotlin service drift..."
	./scripts/check-kotlin-service-drift.sh

kt-check: kt-test kt-check-drift
	@echo "==> Kotlin SDK checks passed"

kt-clean:
	cd kotlin && ./gradlew clean

# ──────────────────────────────────────────────
# Conformance
# ──────────────────────────────────────────────

conformance-build:
	@echo "==> Building conformance runners..."
	cd conformance/runner/go && go build -o conformance-runner .
	cd conformance/runner/typescript && npm ci
	cd kotlin && ./gradlew :conformance:build

conformance-go:
	@echo "==> Running Go conformance..."
	cd conformance/runner/go && go build -o conformance-runner . && ./conformance-runner ../../tests/

conformance-typescript:
	@if [ -f conformance/runner/typescript/package.json ]; then \
		echo "==> Running TypeScript conformance..."; \
		cd conformance/runner/typescript && npx vitest run; \
	else echo "SKIP: TypeScript conformance runner not found"; fi

conformance-ruby:
	@if [ -f conformance/runner/ruby/runner.rb ]; then \
		echo "==> Running Ruby conformance..."; \
		cd conformance/runner/ruby && bundle exec ruby runner.rb ../../tests/; \
	else echo "SKIP: Ruby conformance runner not found"; fi

conformance-kotlin:
	@if find kotlin/conformance/src -name "*.kt" 2>/dev/null | grep -q .; then \
		echo "==> Running Kotlin conformance..."; \
		cd kotlin && ./gradlew :conformance:run; \
	else echo "SKIP: Kotlin conformance runner has no source files"; fi

conformance-swift:
	@if [ -f conformance/runner/swift/Package.swift ]; then \
		echo "==> Running Swift conformance..."; \
		cd conformance/runner/swift && swift run ConformanceRunner ../../tests/; \
	else echo "SKIP: Swift conformance runner not found"; fi

conformance: conformance-go conformance-typescript conformance-ruby conformance-kotlin
	@echo "==> All conformance tests passed"

# ──────────────────────────────────────────────
# Version & Release
# ──────────────────────────────────────────────

bump: ## Bump version: make bump VERSION=x.y.z
	@test -n "$(VERSION)" || (echo "Usage: make bump VERSION=x.y.z" && exit 1)
	@echo "==> Bumping version to $(VERSION)..."
	./scripts/bump-version.sh $(VERSION)
	@echo "  Version bumped to $(VERSION)"

release: ## Release: make release VERSION=x.y.z
	@test -n "$(VERSION)" || (echo "Usage: make release VERSION=x.y.z" && exit 1)
	@echo "==> Releasing v$(VERSION)..."
	@grep -qF 'Version = "$(VERSION)"' go/pkg/fizzy/version.go || \
		{ echo "ERROR: Go version does not match. Run 'make bump VERSION=$(VERSION)' first."; exit 1; }
	@grep -qF '"version": "$(VERSION)"' typescript/package.json || \
		{ echo "ERROR: TypeScript version does not match."; exit 1; }
	@grep -qF 'VERSION = "$(VERSION)"' ruby/lib/fizzy/version.rb || \
		{ echo "ERROR: Ruby version does not match."; exit 1; }
	@grep -qF 'sdkVersion = "$(VERSION)"' swift/Sources/Fizzy/FizzyConfig.swift || \
		{ echo "ERROR: Swift version does not match."; exit 1; }
	@grep -qF 'VERSION = "$(VERSION)"' kotlin/sdk/src/commonMain/kotlin/com/basecamp/fizzy/FizzyConfig.kt || \
		{ echo "ERROR: Kotlin version does not match."; exit 1; }
	@grep -qF 'VERSION = "$(VERSION)"' typescript/src/client.ts || \
		{ echo "ERROR: TypeScript client.ts version does not match."; exit 1; }
	@git diff --quiet && git diff --cached --quiet && \
		test -z "$$(git status --porcelain)" || \
		{ echo "ERROR: Working tree has uncommitted or untracked changes."; git status --short; exit 1; }
	$(MAKE) check
	git tag "v$(VERSION)"
	git push origin main "v$(VERSION)"
	@echo "  Released v$(VERSION)"

audit-check: ## Check rubric audit freshness and must-pass criteria
	@echo "==> Checking rubric audit..."
	@test -f rubric-audit.json || (echo "ERROR: rubric-audit.json not found" && exit 1)
	@for c in 1A.6 1B.2 1C.3; do \
		pass=$$(jq -r --arg c "$$c" '.criteria[$$c].pass // empty' rubric-audit.json); \
		if [ "$$pass" != "true" ]; then \
			echo "ERROR: Must-pass criterion $$c is not passing in rubric-audit.json" && exit 1; \
		fi; \
	done
	@audit_date=$$(jq -r '.date' rubric-audit.json); \
		days_old=$$(( ( $$(date +%s) - $$(date -j -f '%Y-%m-%d' "$$audit_date" +%s 2>/dev/null || date -d "$$audit_date" +%s) ) / 86400 )); \
		if [ "$$days_old" -gt 30 ]; then \
			echo "ERROR: rubric-audit.json is $$days_old days old (max 30)" && exit 1; \
		fi
	@echo "  rubric-audit.json is fresh and must-pass criteria verified"

# ──────────────────────────────────────────────
# Combined
# ──────────────────────────────────────────────

check-mvp: smithy-check behavior-model-check url-routes-check sync-api-version-check go-check ## Fast MVP checks
	@echo "==> MVP checks passed"

check-full: check-mvp provenance-check audit-check ts-check rb-check swift-check kt-check conformance ## Full CI-grade checks
	@echo "==> Full checks passed"

check: smithy-check behavior-model-check url-routes-check sync-api-version-check provenance-check audit-check go-check ts-check rb-check swift-check kt-check conformance ## Run all checks
	@echo "==> All checks passed"

clean: smithy-clean go-clean ts-clean rb-clean swift-clean kt-clean ## Clean all build artifacts
	@echo "==> Cleaned"

help: ## Show this help
	@echo "Fizzy SDK Makefile"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}'
