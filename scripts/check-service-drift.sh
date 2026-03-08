#!/usr/bin/env bash
set -euo pipefail

# Check Go service drift: verify the operations registry matches OpenAPI
# and that generated types exist.

OPENAPI="openapi.json"
GEN_TYPES="go/pkg/generated/types.gen.go"
REGISTRY="go/pkg/fizzy/operations_registry.go"

if [ ! -f "$OPENAPI" ]; then
  echo "SKIP: openapi.json not found"
  exit 0
fi

# Check generated types
if [ ! -f "$GEN_TYPES" ]; then
  echo "ERROR: Generated types not found at $GEN_TYPES"
  echo "Run: cd go && go generate ./..."
  exit 1
fi

GEN_COUNT=$(grep -c '^type ' "$GEN_TYPES" 2>/dev/null || true)
if [ "$GEN_COUNT" -eq 0 ]; then
  echo "ERROR: No types found in $GEN_TYPES"
  exit 1
fi

# Check operations registry exists
if [ ! -f "$REGISTRY" ]; then
  echo "ERROR: Operations registry not found at $REGISTRY"
  exit 1
fi

TMPSCRIPT=$(mktemp)
trap 'rm -f "$TMPSCRIPT"' EXIT
cat > "$TMPSCRIPT" << 'JQSCRIPT'
jq -r '.paths | to_entries[] | .value | to_entries[] | select(.key | test("^(get|post|put|patch|delete)$")) | .value.operationId | select(. != null)' "$1"
JQSCRIPT

# Extract operationIds from OpenAPI
openapi_ops=$(bash "$TMPSCRIPT" "$OPENAPI" | LC_ALL=C sort -u)

# Extract operationIds from Go registry (map keys: first quoted string on each entry line)
registry_ops=$(grep -E '^\s+"[A-Z]' "$REGISTRY" | sed 's/^[[:space:]]*"\([^"]*\)".*/\1/' | LC_ALL=C sort -u)

missing=$(comm -23 <(echo "$openapi_ops") <(echo "$registry_ops"))
extra=$(comm -13 <(echo "$openapi_ops") <(echo "$registry_ops"))

echo "Generated types: $GEN_COUNT"
echo "OpenAPI operations: $(echo "$openapi_ops" | wc -l | tr -d ' ')"
echo "Registry operations: $(echo "$registry_ops" | wc -l | tr -d ' ')"

if [ -n "$missing" ] || [ -n "$extra" ]; then
  [ -n "$missing" ] && echo "" && echo "MISSING from Go registry:" && echo "$missing" | sed 's/^/  /'
  [ -n "$extra" ] && echo "" && echo "EXTRA in Go registry:" && echo "$extra" | sed 's/^/  /'
  exit 1
fi

echo "No Go service drift detected."
