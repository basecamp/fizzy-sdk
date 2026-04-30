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

# Sync lockfiles
echo "Syncing TypeScript lockfile..."
cd typescript && npm install --package-lock-only 2>/dev/null && cd ..

echo "Syncing Ruby lockfile..."
cd ruby && bundle install 2>/dev/null && cd ..

echo "Version bumped to $VERSION"
