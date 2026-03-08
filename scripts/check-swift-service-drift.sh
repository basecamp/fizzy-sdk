#!/usr/bin/env bash
set -euo pipefail

# Check Swift service drift against OpenAPI.

OPENAPI="openapi.json"
SWIFT_SERVICES="swift/Sources/Fizzy/Generated/Services"

if [ ! -f "$OPENAPI" ]; then
  echo "SKIP: openapi.json not found"
  exit 0
fi

if [ ! -d "$SWIFT_SERVICES" ] || ! ls "$SWIFT_SERVICES"/*.swift >/dev/null 2>&1; then
  echo "SKIP: No generated Swift service files found"
  exit 0
fi

# Extract operationIds from OpenAPI using HTTP method allowlist
openapi_ops=$(jq -r '[.paths | to_entries[] | .value | to_entries[] | select(.key | test("^(get|post|put|patch|delete)$")) | .value.operationId | select(. != null)] | .[]' "$OPENAPI" | LC_ALL=C sort -u)

# Extract operation strings from generated Swift service files
swift_ops=$(grep -rohE 'operation: "[^"]*"' "$SWIFT_SERVICES"/*.swift 2>/dev/null | sed 's/operation: "\(.*\)"/\1/' | LC_ALL=C sort -u)

missing=$(comm -23 <(echo "$openapi_ops") <(echo "$swift_ops"))
extra=$(comm -13 <(echo "$openapi_ops") <(echo "$swift_ops"))

if [ -n "$missing" ] || [ -n "$extra" ]; then
  [ -n "$missing" ] && echo "MISSING from Swift:" && echo "$missing" | sed 's/^/  /'
  [ -n "$extra" ] && echo "EXTRA in Swift:" && echo "$extra" | sed 's/^/  /'
  exit 1
fi

echo "No Swift service drift detected."
