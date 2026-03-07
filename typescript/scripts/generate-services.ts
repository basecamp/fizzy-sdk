#!/usr/bin/env node
/**
 * Generates TypeScript service classes from OpenAPI spec.
 *
 * Usage: npx tsx scripts/generate-services.ts [--openapi ../openapi.json] [--output src/generated/services]
 *
 * Produces:
 * 1. Type exports for response and request types
 * 2. Documented interfaces for requests/options
 * 3. Clean method signatures with proper types
 * 4. Rich JSDoc documentation
 */

import * as fs from "fs";
import * as path from "path";

// =============================================================================
// Types
// =============================================================================

interface OpenAPISpec {
  openapi: string;
  info: { title: string; version: string };
  paths: Record<string, PathItem>;
  components: {
    schemas: Record<string, Schema>;
  };
}

interface PathItem {
  [method: string]: Operation | undefined;
}

interface Operation {
  operationId: string;
  description?: string;
  summary?: string;
  tags?: string[];
  parameters?: Parameter[];
  requestBody?: RequestBody;
  responses?: Record<string, Response>;
  "x-fizzy-pagination"?: {
    style: string;
    maxPageSize?: number;
    pageParam?: string;
  };
}

interface Parameter {
  name: string;
  in: "path" | "query" | "header";
  description?: string;
  required?: boolean;
  schema: Schema;
}

interface RequestBody {
  content?: {
    "application/json"?: { schema: Schema };
    "application/octet-stream"?: { schema: Schema };
  };
  required?: boolean;
}

interface Response {
  description: string;
  content?: {
    "application/json"?: { schema: Schema };
  };
}

interface Schema {
  type?: string;
  format?: string;
  description?: string;
  $ref?: string;
  properties?: Record<string, Schema>;
  required?: string[];
  items?: Schema;
  "x-go-type"?: string;
}

interface ParsedOperation {
  operationId: string;
  methodName: string;
  httpMethod: "GET" | "POST" | "PUT" | "DELETE" | "PATCH";
  path: string;
  description: string;
  pathParams: PathParam[];
  queryParams: QueryParam[];
  bodySchemaRef?: string;
  bodyProperties: BodyProperty[];
  bodyRequired: boolean;
  bodyContentType?: "json" | "octet-stream";
  responseSchemaRef?: string;
  returnsArray: boolean;
  returnsVoid: boolean;
  isMutation: boolean;
  resourceType: string;
  hasPagination: boolean;
}

interface PathParam {
  name: string;
  type: string;
  description?: string;
}

interface QueryParam {
  name: string;
  type: string;
  required: boolean;
  description?: string;
}

interface BodyProperty {
  name: string;
  type: string;
  required: boolean;
  description?: string;
  formatHint?: string;
}

interface ServiceDefinition {
  name: string;
  className: string;
  description: string;
  operations: ParsedOperation[];
  types: Map<string, TypeDefinition>;
}

interface TypeDefinition {
  name: string;
  schemaRef: string;
  description?: string;
  isArray?: boolean;
}

// =============================================================================
// Configuration
// =============================================================================

/**
 * Tag to service name mapping for Fizzy's 15 services.
 */
const TAG_TO_SERVICE: Record<string, string> = {
  Identity: "Identity",
  Boards: "Boards",
  Columns: "Columns",
  Cards: "Cards",
  Comments: "Comments",
  Steps: "Steps",
  Reactions: "Reactions",
  Notifications: "Notifications",
  Tags: "Tags",
  Users: "Users",
  Pins: "Pins",
  Uploads: "Uploads",
  Webhooks: "Webhooks",
  Sessions: "Sessions",
  Devices: "Devices",
};

/**
 * Derive service name from operationId when tags are absent.
 * Uses suffix matching with explicit overrides for compound/ambiguous names.
 */
function deriveServiceName(operationId: string): string {
  const overrides: Record<string, string> = {
    GetMyIdentity: "Identity",
    CreateDirectUpload: "Uploads",
    RedeemMagicLink: "Sessions",
    CompleteSignup: "Sessions",
    GetNotificationTray: "Notifications",
    BulkReadNotifications: "Notifications",
    DeleteCardImage: "Cards",
  };
  if (overrides[operationId]) return overrides[operationId]!;

  // Suffix matching — longest suffixes first to avoid false matches
  const suffixMap: [string, string][] = [
    ["CommentReactions", "Reactions"],
    ["CommentReaction", "Reactions"],
    ["CardReactions", "Reactions"],
    ["CardReaction", "Reactions"],
    ["Notifications", "Notifications"],
    ["Notification", "Notifications"],
    ["Comments", "Comments"],
    ["Comment", "Comments"],
    ["Webhooks", "Webhooks"],
    ["Webhook", "Webhooks"],
    ["Columns", "Columns"],
    ["Column", "Columns"],
    ["Boards", "Boards"],
    ["Board", "Boards"],
    ["Cards", "Cards"],
    ["Card", "Cards"],
    ["Steps", "Steps"],
    ["Step", "Steps"],
    ["Users", "Users"],
    ["User", "Users"],
    ["Tags", "Tags"],
    ["Pins", "Pins"],
    ["Session", "Sessions"],
    ["Device", "Devices"],
  ];

  for (const [suffix, service] of suffixMap) {
    if (operationId.endsWith(suffix)) return service;
  }

  return "Miscellaneous";
}

/**
 * Verb extraction patterns for operationId -> method name mapping.
 */
const VERB_PATTERNS = [
  { prefix: "List", method: "list" },
  { prefix: "Get", method: "get" },
  { prefix: "Create", method: "create" },
  { prefix: "Update", method: "update" },
  { prefix: "Delete", method: "delete" },
  { prefix: "Close", method: "close" },
  { prefix: "Reopen", method: "reopen" },
  { prefix: "Postpone", method: "postpone" },
  { prefix: "Triage", method: "triage" },
  { prefix: "UnTriage", method: "untriage" },
  { prefix: "Gold", method: "gold" },
  { prefix: "Ungold", method: "ungold" },
  { prefix: "Assign", method: "assign" },
  { prefix: "SelfAssign", method: "selfAssign" },
  { prefix: "Tag", method: "tag" },
  { prefix: "Watch", method: "watch" },
  { prefix: "Unwatch", method: "unwatch" },
  { prefix: "Pin", method: "pin" },
  { prefix: "Unpin", method: "unpin" },
  { prefix: "Move", method: "move" },
  { prefix: "Read", method: "read" },
  { prefix: "Unread", method: "unread" },
  { prefix: "Bulk", method: "bulk" },
  { prefix: "Activate", method: "activate" },
  { prefix: "Deactivate", method: "deactivate" },
  { prefix: "Register", method: "register" },
  { prefix: "Unregister", method: "unregister" },
  { prefix: "Redeem", method: "redeem" },
  { prefix: "Destroy", method: "destroy" },
  { prefix: "Complete", method: "complete" },
];

/**
 * Method name overrides for specific operationIds.
 */
const METHOD_NAME_OVERRIDES: Record<string, string> = {
  GetMyIdentity: "me",
  CloseCard: "close",
  ReopenCard: "reopen",
  PostponeCard: "postpone",
  TriageCard: "triage",
  UnTriageCard: "untriage",
  GoldCard: "gold",
  UngoldCard: "ungold",
  AssignCard: "assign",
  SelfAssignCard: "selfAssign",
  TagCard: "tag",
  WatchCard: "watch",
  UnwatchCard: "unwatch",
  PinCard: "pin",
  UnpinCard: "unpin",
  MoveCard: "move",
  DeleteCardImage: "deleteImage",
  ListCardReactions: "listForCard",
  CreateCardReaction: "createForCard",
  DeleteCardReaction: "deleteForCard",
  ListCommentReactions: "listForComment",
  CreateCommentReaction: "createForComment",
  DeleteCommentReaction: "deleteForComment",
  ReadNotification: "read",
  UnreadNotification: "unread",
  BulkReadNotifications: "bulkRead",
  GetNotificationTray: "tray",
  CreateDirectUpload: "createDirect",
  ActivateWebhook: "activate",
  DeactivateUser: "deactivate",
  CreateSession: "create",
  RedeemMagicLink: "redeemMagicLink",
  DestroySession: "destroy",
  CompleteSignup: "completeSignup",
  RegisterDevice: "register",
  UnregisterDevice: "unregister",
};

/**
 * Maps OpenAPI schema names to friendly type names.
 */
const TYPE_ALIASES: Record<string, [string, "response" | "request" | "entity"]> = {
  Board: ["Board", "entity"],
  Column: ["Column", "entity"],
  Card: ["Card", "entity"],
  Comment: ["Comment", "entity"],
  Step: ["Step", "entity"],
  Reaction: ["Reaction", "entity"],
  Notification: ["Notification", "entity"],
  Tag: ["Tag", "entity"],
  User: ["User", "entity"],
  Pin: ["Pin", "entity"],
  Webhook: ["Webhook", "entity"],
  Session: ["Session", "entity"],
  Device: ["Device", "entity"],
  Identity: ["Identity", "entity"],
  NotificationTray: ["NotificationTray", "entity"],
  DirectUpload: ["DirectUpload", "entity"],
};

const PROPERTY_HINTS: Record<string, string> = {
  content: "Text content",
  description: "Rich text description (HTML)",
  name: "Display name",
  title: "Title",
  subject: "Subject line",
  body: "Body content (Markdown or HTML)",
  notify: "Whether to send notifications",
  position: "Position for ordering (1-based)",
  status: "Status filter",
  assignee_ids: "User IDs to assign to",
  due_on: "Due date",
  color: "Color value",
  icon: "Icon identifier",
  enabled: "Whether this is enabled",
};

function enrichDescription(desc: string): string {
  let result = desc.replace(/\s*\(returns \d+ [^)]+\)/g, "");
  if (/^Delete /i.test(result) && !/can be recovered/i.test(result)) {
    result += ". Deleted items cannot be recovered.";
  }
  return result;
}

// =============================================================================
// Schema Utilities
// =============================================================================

let globalSchemas: Record<string, Schema> = {};

function setSchemas(schemas: Record<string, Schema>) {
  globalSchemas = schemas;
}

function resolveRef(ref: string): string {
  return ref.split("/").pop() || "";
}

function resolveSchema(schemaOrRef: Schema): Schema | undefined {
  if (schemaOrRef.$ref) {
    const refName = resolveRef(schemaOrRef.$ref);
    return globalSchemas[refName];
  }
  return schemaOrRef;
}

function getSchemaProperties(schemaRef: string): { properties: Record<string, Schema>; required: string[] } {
  const schema = globalSchemas[schemaRef];
  if (!schema) return { properties: {}, required: [] };
  return {
    properties: schema.properties || {},
    required: schema.required || [],
  };
}

function schemaToTsType(schema: Schema, forInterface = false): string {
  if (schema.$ref) {
    const refName = resolveRef(schema.$ref);
    return forInterface ? `components["schemas"]["${refName}"]` : refName;
  }
  switch (schema.type) {
    case "integer":
      return "number";
    case "boolean":
      return "boolean";
    case "array":
      return schema.items ? `${schemaToTsType(schema.items, forInterface)}[]` : "unknown[]";
    case "object":
      return "Record<string, unknown>";
    default:
      return "string";
  }
}

function getFormatHint(schema: Schema): string | undefined {
  if (schema["x-go-type"] === "types.Date") return "YYYY-MM-DD";
  if (schema["x-go-type"] === "time.Time" || schema["x-go-type"] === "types.DateTime") {
    return "RFC3339 (e.g., 2024-12-15T09:00:00Z)";
  }
  if (schema.format === "date") return "YYYY-MM-DD";
  if (schema.format === "date-time") return "RFC3339";
  return undefined;
}

function parsePipeEnum(description: string | undefined): string | null {
  if (!description) return null;
  const parts = description.split("|");
  if (parts.length < 2) return null;
  if (!parts.every((p) => p.length > 0 && !p.includes(" "))) return null;
  return parts.map((p) => `"${p}"`).join(" | ");
}

// =============================================================================
// Parsing Functions
// =============================================================================

function extractMethodName(operationId: string): string {
  if (METHOD_NAME_OVERRIDES[operationId]) {
    return METHOD_NAME_OVERRIDES[operationId]!;
  }

  for (const { prefix, method } of VERB_PATTERNS) {
    if (operationId.startsWith(prefix)) {
      const remainder = operationId.slice(prefix.length);
      if (!remainder) return method;
      const resource = remainder.charAt(0).toLowerCase() + remainder.slice(1);
      if (isSimpleResource(resource)) return method;
      return method === "get" ? resource : method + remainder;
    }
  }

  return operationId.charAt(0).toLowerCase() + operationId.slice(1);
}

function isSimpleResource(resource: string): boolean {
  const simpleResources = [
    "board", "boards", "column", "columns", "card", "cards",
    "comment", "comments", "step", "steps", "reaction", "reactions",
    "notification", "notifications", "tag", "tags", "user", "users",
    "pin", "pins", "webhook", "webhooks", "session", "sessions",
    "device", "devices", "upload", "uploads", "identity",
  ];
  return simpleResources.includes(resource.toLowerCase());
}

function extractResourceType(operationId: string): string {
  for (const { prefix } of VERB_PATTERNS) {
    if (operationId.startsWith(prefix)) {
      const remainder = operationId.slice(prefix.length);
      if (!remainder) return "resource";
      const snakeCase = remainder
        .replace(/([A-Z])/g, "_$1")
        .toLowerCase()
        .replace(/^_/, "");
      return snakeCase;
    }
  }
  return operationId.toLowerCase();
}

function parseOperation(
  pathKey: string,
  httpMethod: string,
  operation: Operation,
): ParsedOperation {
  const operationId = operation.operationId;
  const method = httpMethod.toUpperCase() as ParsedOperation["httpMethod"];
  const isMutation = method !== "GET";
  const description = enrichDescription(operation.description || operation.summary || operationId);
  const hasPagination = !!operation["x-fizzy-pagination"];

  // Path params
  const pathParams: PathParam[] = [];
  const queryParams: QueryParam[] = [];

  for (const param of operation.parameters ?? []) {
    if (param.name === "accountId") continue;

    if (param.in === "path") {
      pathParams.push({
        name: param.name,
        type: schemaToTsType(param.schema),
        description: param.description,
      });
    } else if (param.in === "query") {
      queryParams.push({
        name: param.name,
        type: schemaToTsType(param.schema),
        required: param.required ?? false,
        description: param.description,
      });
    }
  }

  // Request body
  const bodyProperties: BodyProperty[] = [];
  let bodySchemaRef: string | undefined;
  let bodyRequired = false;
  let bodyContentType: ParsedOperation["bodyContentType"];

  if (operation.requestBody) {
    bodyRequired = operation.requestBody.required ?? false;

    if (operation.requestBody.content?.["application/octet-stream"]) {
      bodyContentType = "octet-stream";
    } else if (operation.requestBody.content?.["application/json"]) {
      bodyContentType = "json";
      const bodySchema = operation.requestBody.content["application/json"].schema;

      if (bodySchema) {
        const resolved = resolveSchema(bodySchema);
        if (resolved) {
          bodySchemaRef = bodySchema.$ref ? resolveRef(bodySchema.$ref) : undefined;
          const { properties, required } = resolved.properties
            ? { properties: resolved.properties, required: resolved.required || [] }
            : { properties: {}, required: [] as string[] };

          for (const [propName, propSchema] of Object.entries(properties)) {
            const propType = parsePipeEnum(propSchema.description) ?? schemaToTsType(propSchema, true);
            bodyProperties.push({
              name: propName,
              type: propType,
              required: required.includes(propName),
              description: propSchema.description || PROPERTY_HINTS[propName],
              formatHint: getFormatHint(propSchema),
            });
          }
        }
      }
    }
  }

  // Response — follow $ref chains through wrapper types (e.g. GetBoardResponseContent -> Board)
  let responseSchemaRef: string | undefined;
  let returnsArray = false;
  let returnsVoid = true;

  const successResponses = ["200", "201"];
  for (const status of successResponses) {
    const resp = operation.responses?.[status];
    if (resp?.content?.["application/json"]?.schema) {
      let schema = resp.content["application/json"].schema;
      returnsVoid = false;

      // Resolve top-level $ref first
      if (schema.$ref) {
        const refName = resolveRef(schema.$ref);
        const resolved = globalSchemas[refName];
        if (resolved) {
          // If the wrapper is itself a $ref (e.g. GetBoardResponseContent -> Board), follow it
          if (resolved.$ref) {
            responseSchemaRef = resolveRef(resolved.$ref);
            break;
          }
          schema = resolved;
        } else {
          responseSchemaRef = refName;
          break;
        }
      }

      if (schema.type === "array" && schema.items?.$ref) {
        returnsArray = true;
        responseSchemaRef = resolveRef(schema.items.$ref);
      } else if (schema.$ref) {
        responseSchemaRef = resolveRef(schema.$ref);
      }
      break;
    }
  }

  // 204 No Content
  if (!responseSchemaRef && operation.responses?.["204"]) {
    returnsVoid = true;
  }

  return {
    operationId,
    methodName: extractMethodName(operationId),
    httpMethod: method,
    path: pathKey,
    description,
    pathParams,
    queryParams,
    bodySchemaRef,
    bodyProperties,
    bodyRequired,
    bodyContentType,
    responseSchemaRef,
    returnsArray,
    returnsVoid,
    isMutation,
    resourceType: extractResourceType(operationId),
    hasPagination,
  };
}

// =============================================================================
// Service Generation
// =============================================================================

function groupOperationsIntoServices(
  operations: ParsedOperation[],
  taggedOps: Map<string, string[]>,
): ServiceDefinition[] {
  const serviceOps = new Map<string, ParsedOperation[]>();

  for (const op of operations) {
    // Find which service this operation belongs to via tag, fall back to operationId heuristic
    let serviceName: string | undefined;

    for (const [tag, ops] of taggedOps) {
      if (ops.includes(op.operationId) && TAG_TO_SERVICE[tag]) {
        serviceName = TAG_TO_SERVICE[tag];
        break;
      }
    }

    if (!serviceName) {
      serviceName = deriveServiceName(op.operationId);
    }

    if (!serviceOps.has(serviceName)) {
      serviceOps.set(serviceName, []);
    }
    serviceOps.get(serviceName)!.push(op);
  }

  // Map entity types to their "home" service to avoid duplicate exports.
  // E.g. "User" belongs to "Users" service, not "Sessions".
  const ENTITY_HOME_SERVICE: Record<string, string> = {
    Board: "Boards", Column: "Columns", Card: "Cards", Comment: "Comments",
    Step: "Steps", Reaction: "Reactions", Notification: "Notifications",
    NotificationTray: "Notifications", Tag: "Tags", User: "Users",
    Pin: "Pins", Webhook: "Webhooks", Session: "Sessions", Device: "Devices",
    Identity: "Identity", DirectUpload: "Uploads",
    PendingAuthentication: "Sessions", SessionAuthorization: "Sessions",
    DeviceRegistration: "Devices",
  };

  const services: ServiceDefinition[] = [];

  for (const [name, ops] of serviceOps) {
    const className = `${name}Service`;
    const types = new Map<string, TypeDefinition>();

    for (const op of ops) {
      if (op.responseSchemaRef) {
        const alias = TYPE_ALIASES[op.responseSchemaRef];
        if (alias) {
          // Only export from the entity's home service to avoid duplicate exports
          const home = ENTITY_HOME_SERVICE[op.responseSchemaRef];
          if (!home || home === name) {
            types.set(op.responseSchemaRef, {
              name: alias[0],
              schemaRef: op.responseSchemaRef,
            });
          }
        }
      }
    }

    services.push({
      name,
      className,
      description: `${name} service for the Fizzy API.`,
      operations: ops,
      types,
    });
  }

  return services.sort((a, b) => a.name.localeCompare(b.name));
}

function generateServiceFile(service: ServiceDefinition): string {
  const lines: string[] = [];

  lines.push("/**");
  lines.push(` * ${service.description}`);
  lines.push(" *");
  lines.push(" * @generated from OpenAPI spec - do not edit directly");
  lines.push(" * Run `npm run generate` to regenerate.");
  lines.push(" */");
  lines.push("");
  lines.push('import { BaseService, type FetchResponse } from "../../services/base.js";');
  const needsPagination = service.operations.some(op => op.hasPagination || op.returnsArray);
  if (needsPagination) {
    lines.push('import { ListResult, type PaginationOptions } from "../../pagination.js";');
  }
  lines.push('import type { components } from "../schema.js";');
  lines.push("");

  // Export entity type aliases
  for (const [schemaRef, typeDef] of service.types) {
    lines.push(`export type ${typeDef.name} = components["schemas"]["${schemaRef}"];`);
  }
  if (service.types.size > 0) lines.push("");

  // Generate request/options interfaces
  for (const op of service.operations) {
    // Query params -> Options interface
    if (op.queryParams.length > 0) {
      const optionsName = makeOptionsName(op);
      lines.push(`export interface ${optionsName} extends PaginationOptions {`);
      for (const q of op.queryParams) {
        if (q.description) {
          lines.push(`  /** ${q.description} */`);
        }
        const optional = q.required ? "" : "?";
        lines.push(`  ${toCamelCase(q.name)}${optional}: ${q.type};`);
      }
      lines.push("}");
      lines.push("");
    }

    // Body properties -> Request interface
    if (op.bodyProperties.length > 0) {
      const requestName = makeRequestName(op);
      lines.push(`export interface ${requestName} {`);
      for (const p of op.bodyProperties) {
        const desc = p.description || "";
        const hint = p.formatHint ? ` (format: ${p.formatHint})` : "";
        if (desc || hint) {
          lines.push(`  /** ${desc}${hint} */`);
        }
        const optional = p.required ? "" : "?";
        lines.push(`  ${toCamelCase(p.name)}${optional}: ${p.type};`);
      }
      lines.push("}");
      lines.push("");
    }
  }

  // Service class
  lines.push(`export class ${service.className} extends BaseService {`);

  for (const op of service.operations) {
    lines.push("");
    lines.push("  /**");
    lines.push(`   * ${op.description}`);
    lines.push("   */");

    const methodSig = generateMethodSignature(op, service.types);
    const methodBody = generateMethodBody(op);

    lines.push(`  ${methodSig} {`);
    lines.push(methodBody);
    lines.push("  }");
  }

  lines.push("}");
  lines.push("");

  return lines.join("\n");
}

function makeOptionsName(op: ParsedOperation): string {
  return `${capitalize(op.methodName)}${capitalize(op.resourceType.replace(/_/g, ""))}Options`;
}

function makeRequestName(op: ParsedOperation): string {
  // Derive from schema ref when available (e.g. "RedeemMagicLinkRequestContent" -> "RedeemMagicLinkRequest")
  if (op.bodySchemaRef) {
    let name = op.bodySchemaRef;
    if (name.endsWith("Content")) {
      name = name.slice(0, -"Content".length);
    }
    if (!name.endsWith("Request")) {
      name += "Request";
    }
    return name;
  }
  return `${capitalize(op.methodName)}${capitalize(op.resourceType.replace(/_/g, ""))}Request`;
}

function generateMethodSignature(op: ParsedOperation, localTypes: Map<string, TypeDefinition>): string {
  const params: string[] = [];

  // Path params (except accountId)
  for (const pp of op.pathParams) {
    params.push(`${toCamelCase(pp.name)}: ${pp.type}`);
  }

  // Body param
  if (op.bodyProperties.length > 0) {
    const requestName = makeRequestName(op);
    const opt = op.bodyRequired ? "" : "?";
    params.push(`body${opt}: ${requestName}`);
  } else if (op.bodyContentType === "octet-stream") {
    params.push("body: Blob | ArrayBuffer | ReadableStream");
  }

  // Query/options param
  if (op.queryParams.length > 0) {
    const optionsName = makeOptionsName(op);
    params.push(`options?: ${optionsName}`);
  } else if (op.hasPagination) {
    params.push("options?: PaginationOptions");
  }

  // Return type — use local alias if exported by this service, otherwise full schema path
  function resolveEntityType(schemaRef: string | undefined): string {
    if (!schemaRef) return "unknown";
    if (localTypes.has(schemaRef)) return localTypes.get(schemaRef)!.name;
    return `components["schemas"]["${schemaRef}"]`;
  }

  let returnType: string;
  if (op.returnsVoid) {
    returnType = "Promise<void>";
  } else if (op.returnsArray) {
    returnType = `Promise<ListResult<${resolveEntityType(op.responseSchemaRef)}>>`;
  } else {
    returnType = `Promise<${resolveEntityType(op.responseSchemaRef)}>`;
  }

  return `async ${op.methodName}(${params.join(", ")}): ${returnType}`;
}

function generateMethodBody(op: ParsedOperation): string {
  const lines: string[] = [];
  const indent = "    ";

  // Build operation info
  const serviceTag = capitalize(op.resourceType.replace(/_/g, " "));
  const opName = capitalize(op.methodName);

  // Determine request method
  const methodFn = op.returnsArray && op.hasPagination ? "requestPaginated" : "request";

  lines.push(`${indent}return this.${methodFn}(`);
  lines.push(`${indent}  {`);
  lines.push(`${indent}    service: "${serviceTag}",`);
  lines.push(`${indent}    operation: "${op.operationId}",`);
  lines.push(`${indent}    resourceType: "${op.resourceType}",`);
  lines.push(`${indent}    isMutation: ${op.isMutation},`);
  lines.push(`${indent}  },`);

  // Build the fetch call
  lines.push(`${indent}  () => this.client.${op.httpMethod}("${op.path}" as never, {`);

  const fetchOpts: string[] = [];

  // Path params
  if (op.pathParams.length > 0) {
    const pathEntries = op.pathParams.map((pp) => toCamelCase(pp.name)).join(", ");
    fetchOpts.push(`${indent}    params: { path: { ${pathEntries} } }`);
  }

  // Query params
  if (op.queryParams.length > 0) {
    const queryEntries = op.queryParams
      .map((q) => `${q.name}: options?.${toCamelCase(q.name)}`)
      .join(", ");
    const pathPart = op.pathParams.length > 0
      ? `path: { ${op.pathParams.map((p) => toCamelCase(p.name)).join(", ")} }, `
      : "";
    // Remove path-only line if one was pushed above
    if (op.pathParams.length > 0) {
      fetchOpts.shift();
    }
    fetchOpts.push(`${indent}    params: { ${pathPart}query: { ${queryEntries} } }`);
  }

  // Body
  if (op.bodyProperties.length > 0) {
    const bodyAccessor = `body${op.bodyRequired ? "" : "?"}`;
    const bodyEntries = op.bodyProperties
      .map((p) => {
        const camel = toCamelCase(p.name);
        return `${p.name}: ${bodyAccessor}.${camel}`;
      })
      .join(", ");
    fetchOpts.push(`${indent}    body: { ${bodyEntries} } as never`);
  }

  for (const opt of fetchOpts) {
    lines.push(`${opt},`);
  }

  lines.push(`${indent}  } as never),`);

  // Pagination options
  if (op.hasPagination) {
    lines.push(`${indent}  options,`);
  }

  lines.push(`${indent});`);

  return lines.join("\n");
}

// =============================================================================
// Utilities
// =============================================================================

function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

function toCamelCase(snakeCase: string): string {
  return snakeCase.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
}

function toKebabCase(name: string): string {
  return name
    .replace(/([a-z])([A-Z])/g, "$1-$2")
    .toLowerCase();
}

// =============================================================================
// Main
// =============================================================================

function main() {
  const args = process.argv.slice(2);
  let openapiPath = path.resolve("src/generated/openapi-stripped.json");
  let outputDir = path.resolve("src/generated/services");

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--openapi" && args[i + 1]) {
      openapiPath = path.resolve(args[i + 1]!);
      i++;
    } else if (args[i] === "--output" && args[i + 1]) {
      outputDir = path.resolve(args[i + 1]!);
      i++;
    }
  }

  if (!fs.existsSync(openapiPath)) {
    console.error(`Error: OpenAPI file not found: ${openapiPath}`);
    process.exit(1);
  }

  const spec: OpenAPISpec = JSON.parse(fs.readFileSync(openapiPath, "utf-8"));
  setSchemas(spec.components?.schemas ?? {});

  // Parse all operations
  const allOps: ParsedOperation[] = [];
  const taggedOps = new Map<string, string[]>();

  for (const [pathKey, pathItem] of Object.entries(spec.paths)) {
    for (const [method, operation] of Object.entries(pathItem)) {
      if (method === "parameters") continue;
      if (!operation || !operation.operationId) continue;

      const parsed = parseOperation(pathKey, method, operation);
      allOps.push(parsed);

      // Track by tag
      const tag = operation.tags?.[0] ?? "Untagged";
      if (!taggedOps.has(tag)) {
        taggedOps.set(tag, []);
      }
      taggedOps.get(tag)!.push(operation.operationId);
    }
  }

  console.log(`Parsed ${allOps.length} operations`);

  // Group into services
  const services = groupOperationsIntoServices(allOps, taggedOps);
  console.log(`Generated ${services.length} services:`);

  // Write output
  fs.mkdirSync(outputDir, { recursive: true });

  for (const service of services) {
    const fileName = `${toKebabCase(service.name)}.ts`;
    const filePath = path.join(outputDir, fileName);
    const content = generateServiceFile(service);

    fs.writeFileSync(filePath, content);
    console.log(`  ${fileName} (${service.operations.length} methods)`);
  }

  // Generate barrel export
  const barrelLines = services.map((s) => {
    const fileName = toKebabCase(s.name);
    return `export * from "./${fileName}.js";`;
  });
  fs.writeFileSync(path.join(outputDir, "index.ts"), barrelLines.join("\n") + "\n");
  console.log("  index.ts (barrel)");
}

main();
