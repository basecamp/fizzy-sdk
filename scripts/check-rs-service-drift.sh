#!/usr/bin/env bash
set -euo pipefail

# Check Rust route drift against OpenAPI: every operationId has a generated route and
# every generated route names an operationId.

OPENAPI="openapi.json"
RS_ROUTES="rust/fizzy-sdk/src/generated/routes.rs"

if [ ! -f "$OPENAPI" ]; then
  echo "SKIP: openapi.json not found"
  exit 0
fi

if [ ! -f "$RS_ROUTES" ]; then
  echo "SKIP: No generated Rust routes found"
  exit 0
fi

# Extract operationIds from OpenAPI using HTTP method allowlist
openapi_ops=$(jq -r '[.paths | to_entries[] | .value | to_entries[] | select(.key | test("^(get|post|put|patch|delete)$")) | .value.operationId | select(. != null)] | .[]' "$OPENAPI" | LC_ALL=C sort -u)

# Extract route ids from the generated route table
rs_ops=$({ grep -ohE 'id: "[A-Za-z0-9_]+"' "$RS_ROUTES" 2>/dev/null || true; } | sed 's/id: "\(.*\)"/\1/' | LC_ALL=C sort -u)

missing=$(comm -23 <(echo "$openapi_ops") <(echo "$rs_ops"))
extra=$(comm -13 <(echo "$openapi_ops") <(echo "$rs_ops"))

if [ -n "$missing" ] || [ -n "$extra" ]; then
  [ -n "$missing" ] && echo "MISSING from Rust:" && echo "$missing" | sed 's/^/  /'
  [ -n "$extra" ] && echo "EXTRA in Rust:" && echo "$extra" | sed 's/^/  /'
  exit 1
fi

echo "No Rust service drift detected."
