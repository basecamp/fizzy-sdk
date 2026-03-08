#!/usr/bin/env tsx
/**
 * Generates PATH_TO_OPERATION mapping from OpenAPI spec.
 *
 * Usage: npx tsx scripts/generate-path-mapping.ts
 *
 * Reads from openapi-stripped.json to ensure operation IDs match metadata.json.
 */

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

const OPENAPI_STRIPPED = resolve(__dirname, "../src/generated/openapi-stripped.json");
const OPENAPI_FULL = resolve(__dirname, "../../openapi.json");
const OUTPUT_PATH = resolve(__dirname, "../src/generated/path-mapping.ts");

interface OpenAPISpec {
  paths: Record<string, Record<string, { operationId?: string }>>;
}

interface PathEntry {
  method: string;
  path: string;
  operationId: string;
}

function resolveOpenAPIPath(): string {
  if (existsSync(OPENAPI_STRIPPED)) {
    return OPENAPI_STRIPPED;
  }
  console.error("Error: openapi-stripped.json not found.");
  console.error("  Expected: src/generated/openapi-stripped.json");
  console.error("\nRun the earlier generate steps first (strip-account-id.ts).");
  process.exit(1);
}

function parseOpenAPI(specPath: string): PathEntry[] {
  const spec: OpenAPISpec = JSON.parse(readFileSync(specPath, "utf-8"));

  // Read full spec to determine which paths are account-scoped.
  // Fail fast if missing — output correctness depends on it.
  if (!existsSync(OPENAPI_FULL)) {
    console.error("Error: openapi.json not found at", OPENAPI_FULL);
    process.exit(1);
  }
  const fullSpec: OpenAPISpec = JSON.parse(readFileSync(OPENAPI_FULL, "utf-8"));
  const fullPaths = new Set(Object.keys(fullSpec.paths));

  const entries: PathEntry[] = [];

  for (const [path, methods] of Object.entries(spec.paths)) {
    for (const [method, details] of Object.entries(methods)) {
      if (method === "parameters") continue;
      if (!details.operationId) continue;

      // Only prepend {accountId} if the full spec had an account-scoped path
      const isAccountScoped = fullPaths.has(`/{accountId}${path}`);
      const fullPath = isAccountScoped ? `/{accountId}${path}` : path;

      entries.push({
        method: method.toUpperCase(),
        path: fullPath,
        operationId: details.operationId,
      });
    }
  }

  entries.sort((a, b) => {
    const pathCmp = a.path.localeCompare(b.path);
    if (pathCmp !== 0) return pathCmp;
    return a.method.localeCompare(b.method);
  });

  return entries;
}

function groupByPrefix(entries: PathEntry[]): Map<string, PathEntry[]> {
  const groups = new Map<string, PathEntry[]>();

  for (const entry of entries) {
    const prefix = getPathPrefix(entry.path);
    if (!groups.has(prefix)) {
      groups.set(prefix, []);
    }
    groups.get(prefix)!.push(entry);
  }

  return groups;
}

function getPathPrefix(path: string): string {
  const patterns: [RegExp, string][] = [
    [/\/boards/, "Boards"],
    [/\/columns/, "Columns"],
    [/\/cards\/\{cardNumber\}\/comments/, "Comments"],
    [/\/cards\/\{cardNumber\}\/steps/, "Steps"],
    [/\/cards\/\{cardNumber\}\/reactions/, "Card Reactions"],
    [/\/comments\/\{commentId\}\/reactions/, "Comment Reactions"],
    [/\/cards/, "Cards"],
    [/\/notifications/, "Notifications"],
    [/\/tags/, "Tags"],
    [/\/users/, "Users"],
    [/\/pins/, "Pins"],
    [/\/uploads/, "Uploads"],
    [/\/webhooks/, "Webhooks"],
    [/\/sessions/, "Sessions"],
    [/\/devices/, "Devices"],
    [/\/me/, "Identity"],
  ];

  for (const [pattern, name] of patterns) {
    if (pattern.test(path)) {
      return name;
    }
  }

  return "Other";
}

function generateCode(entries: PathEntry[]): string {
  const groups = groupByPrefix(entries);
  const lines: string[] = [];

  lines.push("/**");
  lines.push(" * Maps HTTP method + path to OpenAPI operationId.");
  lines.push(" *");
  lines.push(" * @generated from OpenAPI spec - do not edit directly");
  lines.push(" * Run `npm run generate` to regenerate.");
  lines.push(" */");
  lines.push("");
  lines.push("export const PATH_TO_OPERATION: Record<string, string> = {");

  let first = true;
  for (const [group, groupEntries] of groups) {
    if (!first) {
      lines.push("");
    }
    first = false;

    lines.push(`  // ${group}`);
    for (const entry of groupEntries) {
      lines.push(`  "${entry.method}:${entry.path}": "${entry.operationId}",`);
    }
  }

  lines.push("};");
  lines.push("");

  return lines.join("\n");
}

function main() {
  const openapiPath = resolveOpenAPIPath();
  console.log(`Reading OpenAPI spec from: ${openapiPath}`);

  const entries = parseOpenAPI(openapiPath);
  console.log(`Found ${entries.length} operations`);

  const code = generateCode(entries);
  writeFileSync(OUTPUT_PATH, code);
  console.log(`Generated: ${OUTPUT_PATH}`);
}

main();
