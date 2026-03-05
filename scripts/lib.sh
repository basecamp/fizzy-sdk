#!/usr/bin/env bash
# Shared shell utilities for SDK scripts.

# Portable sed -i wrapper (macOS vs GNU)
sedi() {
  local tmp
  tmp=$(mktemp)
  sed "$1" "$2" > "$tmp" && mv "$tmp" "$2"
}
