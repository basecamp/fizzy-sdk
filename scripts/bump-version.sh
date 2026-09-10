#!/usr/bin/env bash
set -euo pipefail

# Bump SDK version across SDK source, manifests, and version assertions.
# Usage: ./scripts/bump-version.sh x.y.z

VERSION="${1:?Usage: bump-version.sh VERSION}"

echo "Bumping version to $VERSION"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

# 1. Go — version.go
sedi "s/^const Version = \"[^\"]*\"/const Version = \"$VERSION\"/" go/pkg/fizzy/version.go

# 2. TypeScript — package.json
sedi "s/\"version\": \"[^\"]*\"/\"version\": \"$VERSION\"/" typescript/package.json

# 3. TypeScript — client.ts
sedi "s/export const VERSION = \"[^\"]*\"/export const VERSION = \"$VERSION\"/" typescript/src/client.ts

# 4. Ruby — version.rb
sedi "s/^  VERSION = \"[^\"]*\"/  VERSION = \"$VERSION\"/" ruby/lib/fizzy/version.rb

# 5. Swift — FizzyConfig.swift
sedi "s/sdkVersion = \"[^\"]*\"/sdkVersion = \"$VERSION\"/" swift/Sources/Fizzy/FizzyConfig.swift

# 6. Kotlin — build.gradle.kts
sedi "s/version = \"[^\"]*\"/version = \"$VERSION\"/" kotlin/sdk/build.gradle.kts

# 7. Kotlin — FizzyConfig.kt
sedi "s/const val VERSION = \"[^\"]*\"/const val VERSION = \"$VERSION\"/" kotlin/sdk/src/commonMain/kotlin/com/basecamp/fizzy/FizzyConfig.kt

# 8. Root — package.json
sedi "s/\"version\": \"[^\"]*\"/\"version\": \"$VERSION\"/" package.json

# 9. Swift — version assertion
sedi "s/FizzyConfig.sdkVersion == \"[^\"]*\"/FizzyConfig.sdkVersion == \"$VERSION\"/" swift/Tests/FizzyTests/FizzyTests.swift

# 10. Rust — Cargo.toml [package] version. The edit is bounded to the [package] table: a
#     bare ^version sed would also match a dependency or [workspace.package] line.
CARGO_TOML=rust/fizzy-sdk/Cargo.toml
tmp=$(mktemp)
awk -v version="$VERSION" '
  /^\[/ { in_package = ($0 == "[package]") }
  in_package && /^version = "/ { $0 = "version = \"" version "\"" }
  { print }
' "$CARGO_TOML" > "$tmp" && mv "$tmp" "$CARGO_TOML"
RS_VERSION=$(cargo metadata --no-deps --format-version 1 --manifest-path rust/Cargo.toml | \
  jq -r '.packages[] | select(.name == "fizzy-sdk") | .version')
if [ "$RS_VERSION" != "$VERSION" ]; then
  echo "ERROR: $CARGO_TOML reads $RS_VERSION after the bump, expected $VERSION" >&2
  exit 1
fi

# Sync lockfiles
echo "Syncing TypeScript lockfiles..."
cd typescript && npm install --package-lock-only 2>/dev/null && cd ..
cd conformance/runner/typescript && npm install --package-lock-only 2>/dev/null && cd ../../..

echo "Syncing Ruby lockfiles..."
cd ruby && bundle install 2>/dev/null && cd ..
cd conformance/runner/ruby && bundle install 2>/dev/null && cd ../../..

# Both Cargo.lock files record the crate's own version
echo "Syncing Rust lockfiles..."
(cd rust && cargo update --workspace --quiet)
(cd conformance/runner/rust && cargo update --workspace --quiet)

echo "Version bumped to $VERSION"
