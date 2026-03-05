#!/usr/bin/env bash
set -euo pipefail

# Check Go service drift: verify service methods match generated client.

GEN="go/pkg/generated/client.gen.go"
SVC_DIR="go/pkg/fizzy"

if [ ! -f "$GEN" ]; then
  echo "SKIP: Generated client not found at $GEN"
  exit 0
fi

# Extract WithResponse method names from generated client
gen_ops=$(grep -oE '[A-Z][A-Za-z]+WithResponse' "$GEN" | sed 's/WithResponse$//' | sort -u)

# Extract service method calls to generated client
svc_ops=$(grep -rohE '\bgen\.[A-Z][A-Za-z]+WithResponse' "$SVC_DIR"/*.go 2>/dev/null | sed 's/.*gen\.\([A-Za-z]*\)WithResponse/\1/' | sort -u)

# Find drift
missing=$(comm -23 <(echo "$svc_ops") <(echo "$gen_ops"))
unwrapped=$(comm -23 <(echo "$gen_ops") <(echo "$svc_ops"))

total_gen=$(echo "$gen_ops" | wc -l | tr -d ' ')
total_svc=$(echo "$svc_ops" | wc -l | tr -d ' ')

echo "Generated operations: $total_gen"
echo "Service-wrapped operations: $total_svc"

if [ -n "$unwrapped" ]; then
  echo ""
  echo "UNWRAPPED (generated but not in service layer — informational):"
  echo "$unwrapped" | sed 's/^/  /'
fi

if [ -n "$missing" ]; then
  echo ""
  echo "MISSING (service calls to non-existent generated ops — FATAL):"
  echo "$missing" | sed 's/^/  /'
  exit 1
fi

echo "No drift detected."
