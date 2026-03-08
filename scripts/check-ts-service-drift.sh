#!/usr/bin/env bash
set -euo pipefail

# Check TypeScript service drift against OpenAPI.

OPENAPI="openapi.json"
TS_SERVICES="typescript/src/generated/services"

if [ ! -f "$OPENAPI" ]; then
  echo "SKIP: openapi.json not found"
  exit 0
fi

if [ ! -d "$TS_SERVICES" ] || ! ls "$TS_SERVICES"/*.ts >/dev/null 2>&1; then
  echo "SKIP: No generated TypeScript service files found"
  exit 0
fi

# Extract operationIds from OpenAPI using HTTP method allowlist
openapi_ops=$(jq -r '[.paths | to_entries[] | .value | to_entries[] | select(.key | test("^(get|post|put|patch|delete)$")) | .value.operationId | select(. != null)] | .[]' "$OPENAPI" | LC_ALL=C sort -u)

# Extract operation strings from generated TypeScript service files
ts_ops=$(grep -rohE 'operation: "[^"]*"' "$TS_SERVICES"/*.ts 2>/dev/null | sed 's/operation: "\(.*\)"/\1/' | LC_ALL=C sort -u)

missing=$(comm -23 <(echo "$openapi_ops") <(echo "$ts_ops"))
extra=$(comm -13 <(echo "$openapi_ops") <(echo "$ts_ops"))

if [ -n "$missing" ] || [ -n "$extra" ]; then
  [ -n "$missing" ] && echo "MISSING from TypeScript:" && echo "$missing" | sed 's/^/  /'
  [ -n "$extra" ] && echo "EXTRA in TypeScript:" && echo "$extra" | sed 's/^/  /'
  exit 1
fi

echo "No TypeScript service drift detected."
