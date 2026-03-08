#!/usr/bin/env bash
set -euo pipefail

# Check Kotlin service drift against OpenAPI.

OPENAPI="openapi.json"
KT_SERVICES="kotlin/sdk/src/commonMain/kotlin/com/basecamp/fizzy/generated/services"

if [ ! -f "$OPENAPI" ]; then
  echo "SKIP: openapi.json not found"
  exit 0
fi

if [ ! -d "$KT_SERVICES" ] || ! ls "$KT_SERVICES"/*.kt >/dev/null 2>&1; then
  echo "SKIP: No generated Kotlin service files found"
  exit 0
fi

# Extract operationIds from OpenAPI using HTTP method allowlist
openapi_ops=$(jq -r '[.paths | to_entries[] | .value | to_entries[] | select(.key | test("^(get|post|put|patch|delete)$")) | .value.operationId | select(. != null)] | .[]' "$OPENAPI" | LC_ALL=C sort -u)

# Extract operation strings from generated Kotlin service files
kt_ops=$(grep -rohE 'operation = "[^"]*"' "$KT_SERVICES"/*.kt 2>/dev/null | sed 's/operation = "\(.*\)"/\1/' | LC_ALL=C sort -u)

missing=$(comm -23 <(echo "$openapi_ops") <(echo "$kt_ops"))
extra=$(comm -13 <(echo "$openapi_ops") <(echo "$kt_ops"))

if [ -n "$missing" ] || [ -n "$extra" ]; then
  [ -n "$missing" ] && echo "MISSING from Kotlin:" && echo "$missing" | sed 's/^/  /'
  [ -n "$extra" ] && echo "EXTRA in Kotlin:" && echo "$extra" | sed 's/^/  /'
  exit 1
fi

echo "No Kotlin service drift detected."
