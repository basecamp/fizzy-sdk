#!/usr/bin/env bash
set -euo pipefail

# Sync the API version from openapi.json to all SDK language files.

OPENAPI="openapi.json"

if [ ! -f "$OPENAPI" ]; then
  echo "ERROR: openapi.json not found." >&2
  exit 1
fi

API_VERSION=$(jq -r '.info.version' "$OPENAPI")
echo "Syncing API version: $API_VERSION"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

# Go
sedi "s/APIVersion = \"[^\"]*\"/APIVersion = \"$API_VERSION\"/" go/pkg/fizzy/version.go

# TypeScript
sedi "s/API_VERSION = \"[^\"]*\"/API_VERSION = \"$API_VERSION\"/" typescript/src/client.ts

# Ruby
sedi "s/API_VERSION = \"[^\"]*\"/API_VERSION = \"$API_VERSION\"/" ruby/lib/fizzy/version.rb

# Kotlin
sedi "s/API_VERSION = \"[^\"]*\"/API_VERSION = \"$API_VERSION\"/" kotlin/sdk/src/commonMain/kotlin/com/basecamp/fizzy/FizzyConfig.kt

# Swift
sedi "s/apiVersion = \"[^\"]*\"/apiVersion = \"$API_VERSION\"/" swift/Sources/Fizzy/FizzyConfig.swift

echo "API version synced to all SDKs"
