#!/usr/bin/env bash
set -euo pipefail

# Check Ruby service drift against OpenAPI.

OPENAPI="openapi.json"
RB_SERVICES="ruby/lib/fizzy/generated/services"

if [ ! -f "$OPENAPI" ]; then
  echo "SKIP: openapi.json not found"
  exit 0
fi

if [ ! -d "$RB_SERVICES" ] || ! ls "$RB_SERVICES"/*.rb >/dev/null 2>&1; then
  echo "SKIP: No generated Ruby service files found"
  exit 0
fi

# Extract operationIds from OpenAPI using HTTP method allowlist
openapi_ops=$(jq -r '[.paths | to_entries[] | .value | to_entries[] | select(.key | test("^(get|post|put|patch|delete)$")) | .value.operationId | select(. != null)] | .[]' "$OPENAPI" | LC_ALL=C sort -u)

# Extract operation strings from generated Ruby service files
rb_ops=$(grep -rohE 'operation: "[^"]*"' "$RB_SERVICES"/*.rb 2>/dev/null | sed 's/operation: "\(.*\)"/\1/' | LC_ALL=C sort -u)

missing=$(comm -23 <(echo "$openapi_ops") <(echo "$rb_ops"))
extra=$(comm -13 <(echo "$openapi_ops") <(echo "$rb_ops"))

if [ -n "$missing" ] || [ -n "$extra" ]; then
  [ -n "$missing" ] && echo "MISSING from Ruby:" && echo "$missing" | sed 's/^/  /'
  [ -n "$extra" ] && echo "EXTRA in Ruby:" && echo "$extra" | sed 's/^/  /'
  exit 1
fi

echo "No Ruby service drift detected."
