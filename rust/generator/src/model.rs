//! The model the emitters render: every schema and every operation, read out of
//! `openapi.json` and `behavior-model.json` and named by `names.toml`.

use std::collections::{BTreeMap, BTreeSet};

use serde::Deserialize;
use serde_json::Value;

use crate::naming::{Naming, service_label};

/// The path parameter every account-scoped route starts with.
pub const ACCOUNT_PARAM: &str = "accountId";

/// Which noun each operation acts on, read from the same `names.toml` the naming overrides
/// come from. Nothing in OpenAPI says it, and the SDKs have to agree on it, so it is written
/// down per service and overridden per operation where the two differ.
#[derive(Deserialize, Default)]
pub struct ResourceTypes {
    #[serde(default)]
    resource_types: BTreeMap<String, String>,
    #[serde(default)]
    operation_resource_types: BTreeMap<String, String>,
}

impl ResourceTypes {
    /// Reads the tables out of `names.toml`.
    pub fn parse(source: &str) -> Result<ResourceTypes, String> {
        toml::from_str(source).map_err(|error| format!("names.toml: {error}"))
    }

    fn for_operation(&self, operation_id: &str, service: &str) -> Result<String, String> {
        if let Some(resource_type) = self.operation_resource_types.get(operation_id) {
            Ok(resource_type.clone())
        } else if let Some(resource_type) = self.resource_types.get(service) {
            Ok(resource_type.clone())
        } else {
            Err(format!(
                "{service} has no resource type; add one to the [resource_types] table in names.toml"
            ))
        }
    }
}

/// Everything the emitters need.
pub struct Model {
    /// `info.version` from `openapi.json`.
    pub api_version: String,
    /// Every schema, in the order `openapi.json` lists them.
    pub schemas: Vec<Schema>,
    /// Every service, alphabetically, each with its operations by method name.
    pub services: Vec<Service>,
}

/// One `components.schemas` entry.
pub struct Schema {
    /// The Rust type name.
    pub name: String,
    /// What the type is.
    pub shape: Shape,
    /// The type is reachable from a request body, so callers build it by hand: it derives
    /// `Default` and is open to struct-literal construction. Anything else is read-only
    /// and `#[non_exhaustive]`, so a field added later is not a breaking change.
    pub constructible: bool,
}

/// A schema is a struct with properties or an alias for another type.
pub enum Shape {
    /// An object with properties.
    Struct(Struct),
    /// A reference, an array or a map standing in for a named type.
    Alias(FieldType),
}

/// The fields of an object schema.
pub struct Struct {
    /// In the order `openapi.json` lists them.
    pub fields: Vec<Field>,
}

/// One property of an object schema.
pub struct Field {
    /// The JSON key.
    pub wire_name: String,
    /// The Rust type.
    pub kind: FieldType,
    /// Listed in the schema's `required`.
    pub required: bool,
    /// The field's type mentions the struct it sits in, so it is boxed.
    pub recursive: bool,
}

/// The Rust type a JSON value reads as.
#[derive(Clone, PartialEq, Debug)]
pub enum FieldType {
    /// `String`.
    String,
    /// A string that must not reach a log: `format: password` or `x-fizzy-sensitive`.
    SensitiveString,
    /// A `*_at` timestamp.
    DateTime,
    /// `bool`.
    Bool,
    /// `i32`.
    Int32,
    /// `i64`.
    Int64,
    /// An object with no properties: `serde_json::Value`.
    Json,
    /// Another schema, by Rust type name.
    Named(String),
    /// `Vec<T>`.
    List(Box<FieldType>),
    /// `BTreeMap<String, T>`.
    Map(Box<FieldType>),
}

/// One service: the struct that groups a set of operations.
pub struct Service {
    /// snake_cased: `boards`, `access_tokens`.
    pub name: String,
    /// Sorted by method name.
    pub operations: Vec<Operation>,
}

impl Service {
    /// The service has an operation that needs no account, so it hangs off `Client`.
    pub fn on_client(&self) -> bool {
        self.operations
            .iter()
            .any(|operation| !operation.account_scoped)
    }

    /// The service has an account-scoped operation, so it hangs off `AccountClient`.
    pub fn on_account(&self) -> bool {
        self.operations
            .iter()
            .any(|operation| operation.account_scoped)
    }
}

/// One operation.
pub struct Operation {
    /// The OpenAPI `operationId`.
    pub id: String,
    /// The service as the hooks name it: `Boards`.
    pub service: String,
    /// The snake_cased method on that struct.
    pub method_name: String,
    /// `GET`, `POST`...
    pub http_method: String,
    /// The path as `openapi.json` writes it, `{accountId}` and all.
    pub path: String,
    /// The path starts with `/{accountId}`.
    pub account_scoped: bool,
    /// The noun the operation acts on, as the hooks report it.
    pub resource_type: String,
    /// In path order, `accountId` left out.
    pub path_params: Vec<PathParam>,
    /// In the order `openapi.json` lists them.
    pub query_params: Vec<QueryParam>,
    /// The request body's Rust type, when there is one.
    pub body: Option<String>,
    /// What a success answers.
    pub response: Response,
    /// Safe to resend: naturally so for its method, or declared so by `x-fizzy-idempotent`.
    pub idempotent: bool,
    /// Reads only.
    pub readonly: bool,
    /// The list is paginated with `Link` headers; this is the page query parameter.
    pub page_param: Option<String>,
    /// The retry budget, or `None` when the operation is sent once and never resent.
    pub retry: Option<Retry>,
}

/// One `{param}` in a path.
pub struct PathParam {
    /// The name inside the braces.
    pub wire_name: String,
    /// How it is typed.
    pub kind: ParamKind,
    /// Where it sits.
    pub role: ParamRole,
}

/// Where a path parameter sits: the last segment names the record itself, anything before
/// it names a parent.
#[derive(Clone, Copy, PartialEq, Debug)]
pub enum ParamRole {
    /// A parent's id.
    Parent,
    /// The record's own id.
    Recording,
}

/// One query parameter.
pub struct QueryParam {
    /// The key on the wire, brackets included: `column_ids[]`.
    pub wire_name: String,
    /// How each value is typed.
    pub kind: ParamKind,
    /// The key repeats, once per value.
    pub list: bool,
    /// The caller must supply it.
    pub required: bool,
}

/// The scalar types a parameter takes.
#[derive(Clone, Copy, PartialEq, Debug)]
pub enum ParamKind {
    /// `&str`
    String,
    /// `bool`
    Bool,
    /// `i32`
    Int32,
    /// `i64`
    Int64,
}

/// What a success answers.
pub enum Response {
    /// No body worth reading.
    Empty,
    /// A JSON body.
    Json(ResponseType),
}

/// A JSON answer: the schema it is declared as, and the type the method hands back — the
/// schema's own target when the schema is an alias (`ListBoardsResponseContent` is
/// `Vec<Board>`, and the method says so).
pub struct ResponseType {
    /// The schema `openapi.json` names.
    pub schema: String,
    /// The Rust type expression the method returns.
    pub rust_type: String,
}

/// The retry budget the behavior model gives an operation.
#[derive(Clone, PartialEq, Debug)]
pub struct Retry {
    /// Total attempts, the first included.
    pub max: u32,
    /// The first backoff, doubled after every attempt.
    pub base_delay_ms: u64,
    /// The statuses that are resent.
    pub retry_on: Vec<u16>,
}

impl Model {
    /// Reads a model out of the two JSON documents.
    pub fn build(
        openapi: &Value,
        behavior: &Value,
        naming: &Naming,
        resource_types: &ResourceTypes,
    ) -> Result<Model, String> {
        let api_version = openapi["info"]["version"]
            .as_str()
            .ok_or("openapi.json has no info.version")?
            .to_string();
        let components = openapi["components"]["schemas"]
            .as_object()
            .ok_or("openapi.json has no components.schemas")?;
        let constructible = request_reachable(openapi, components)?;
        let schemas = build_schemas(components, naming, &constructible)?;
        let services = build_services(openapi, behavior, naming, resource_types, &schemas)?;
        verify_redaction(behavior, &schemas)?;
        Ok(Model {
            api_version,
            schemas,
            services,
        })
    }

    /// Every operation across every service, by operation id.
    pub fn operations(&self) -> Vec<&Operation> {
        let mut operations: Vec<&Operation> = self
            .services
            .iter()
            .flat_map(|service| &service.operations)
            .collect();
        operations.sort_by(|a, b| a.id.cmp(&b.id));
        operations
    }

    /// The schema with this Rust name.
    pub fn schema(&self, name: &str) -> Option<&Schema> {
        self.schemas.iter().find(|schema| schema.name == name)
    }
}

/// The schemas a caller builds by hand: every request body, and every schema reachable
/// from one.
fn request_reachable(
    openapi: &Value,
    components: &serde_json::Map<String, Value>,
) -> Result<BTreeSet<String>, String> {
    let mut pending: Vec<String> = Vec::new();
    for (path, item) in openapi["paths"].as_object().into_iter().flatten() {
        for (http_method, operation) in
            item.as_object().ok_or(format!("{path} is not an object"))?
        {
            if !is_http_method(http_method) {
                continue;
            }
            if let Some(reference) =
                operation["requestBody"]["content"]["application/json"]["schema"]["$ref"].as_str()
            {
                pending.push(reference_name(reference));
            }
        }
    }
    let mut reachable = BTreeSet::new();
    while let Some(name) = pending.pop() {
        if !reachable.insert(name.clone()) {
            continue;
        }
        let schema = components
            .get(&name)
            .ok_or(format!("request body references unknown schema {name}"))?;
        collect_references(schema, &mut pending);
    }
    Ok(reachable)
}

fn collect_references(value: &Value, into: &mut Vec<String>) {
    match value {
        Value::Object(object) => {
            if let Some(reference) = object.get("$ref").and_then(Value::as_str) {
                into.push(reference_name(reference));
            }
            for child in object.values() {
                collect_references(child, into);
            }
        }
        Value::Array(items) => {
            for item in items {
                collect_references(item, into);
            }
        }
        _ => {}
    }
}

fn build_schemas(
    components: &serde_json::Map<String, Value>,
    naming: &Naming,
    constructible: &BTreeSet<String>,
) -> Result<Vec<Schema>, String> {
    let mut schemas = Vec::new();
    for (schema_name, schema) in components {
        let name = naming.type_for(schema_name);
        let shape = if let Some(properties) = schema.get("properties") {
            let required: BTreeSet<&str> = schema["required"]
                .as_array()
                .map(|list| list.iter().filter_map(Value::as_str).collect())
                .unwrap_or_default();
            let properties = properties
                .as_object()
                .ok_or(format!("{name}.properties is not an object"))?;
            let mut fields = Vec::new();
            for (wire_name, property) in properties {
                let kind = match field_type(wire_name, property, naming)? {
                    FieldType::String if naming.is_sensitive(schema_name, wire_name) => {
                        FieldType::SensitiveString
                    }
                    kind => kind,
                };
                fields.push(Field {
                    wire_name: wire_name.clone(),
                    recursive: kind.mentions(&name),
                    kind,
                    required: required.contains(wire_name.as_str()),
                });
            }
            Shape::Struct(Struct { fields })
        } else {
            Shape::Alias(field_type(schema_name, schema, naming)?)
        };
        schemas.push(Schema {
            name,
            shape,
            constructible: constructible.contains(schema_name),
        });
    }
    Ok(schemas)
}

fn field_type(name: &str, property: &Value, naming: &Naming) -> Result<FieldType, String> {
    if let Some(reference) = property.get("$ref").and_then(Value::as_str) {
        return Ok(FieldType::Named(
            naming.type_for(&reference_name(reference)),
        ));
    }
    let format = property["format"].as_str();
    match property["type"].as_str() {
        Some("string") => Ok(string_type(name, property, format)),
        Some("boolean") => Ok(FieldType::Bool),
        Some("integer") => match format {
            Some("int32") => Ok(FieldType::Int32),
            _ => Ok(FieldType::Int64),
        },
        Some("array") => Ok(FieldType::List(Box::new(field_type(
            name,
            &property["items"],
            naming,
        )?))),
        Some("object") => {
            if let Some(values) = property.get("additionalProperties") {
                Ok(FieldType::Map(Box::new(field_type(name, values, naming)?)))
            } else {
                Ok(FieldType::Json)
            }
        }
        other => Err(format!("{name}: unsupported schema type {other:?}")),
    }
}

/// A string is sensitive when the model says so twice over: `x-fizzy-sensitive` marks the
/// members Smithy's `@fizzySensitive` names, and `format: password` is what Smithy's own
/// `@sensitive` becomes in OpenAPI (a person's name, say). Either keeps it out of logs.
fn string_type(name: &str, property: &Value, format: Option<&str>) -> FieldType {
    if property.get("x-fizzy-sensitive").is_some() || format == Some("password") {
        FieldType::SensitiveString
    } else if format == Some("date-time") || name.ends_with("_at") {
        FieldType::DateTime
    } else {
        FieldType::String
    }
}

fn build_services(
    openapi: &Value,
    behavior: &Value,
    naming: &Naming,
    resource_types: &ResourceTypes,
    schemas: &[Schema],
) -> Result<Vec<Service>, String> {
    let paths = openapi["paths"]
        .as_object()
        .ok_or("openapi.json has no paths")?;
    let behaviors = behavior["operations"]
        .as_object()
        .ok_or("behavior-model.json has no operations")?;
    let mut services: BTreeMap<String, Vec<Operation>> = BTreeMap::new();

    for (path, item) in paths {
        for (http_method, operation) in
            item.as_object().ok_or(format!("{path} is not an object"))?
        {
            if !is_http_method(http_method) {
                continue;
            }
            let id = operation["operationId"]
                .as_str()
                .ok_or(format!("{http_method} {path} has no operationId"))?;
            let service = naming.service_for(id)?;
            let semantics = behaviors
                .get(id)
                .ok_or(format!("{id} is missing from behavior-model.json"))?;
            let (account_scoped, path_params) = path_params(operation, path)?;
            let operation = Operation {
                id: id.to_string(),
                service: service_label(&service),
                method_name: naming.method_for(id, &service)?,
                http_method: http_method.to_uppercase(),
                path: path.clone(),
                account_scoped,
                resource_type: resource_types.for_operation(id, &service)?,
                path_params,
                query_params: query_params(operation)?,
                body: body_of(operation, naming),
                response: response_of(operation, naming, schemas)?,
                idempotent: idempotent(http_method, operation, semantics),
                readonly: semantics["readonly"].as_bool().unwrap_or(false),
                page_param: pagination(semantics, id)?,
                retry: retry(semantics, id)?,
            };
            services.entry(service).or_default().push(operation);
        }
    }

    let mut result = Vec::new();
    for (name, mut operations) in services {
        operations.sort_by(|a, b| a.method_name.cmp(&b.method_name).then(a.id.cmp(&b.id)));
        for pair in operations.windows(2) {
            if pair[0].method_name == pair[1].method_name {
                return Err(format!(
                    "{} and {} both become {}::{}; add an [operation_methods] override to names.toml",
                    pair[0].id, pair[1].id, name, pair[0].method_name
                ));
            }
        }
        result.push(Service { name, operations });
    }
    Ok(result)
}

fn is_http_method(name: &str) -> bool {
    matches!(name, "get" | "post" | "put" | "patch" | "delete")
}

/// The path's parameters, and whether the first of them is the account.
fn path_params(operation: &Value, path: &str) -> Result<(bool, Vec<PathParam>), String> {
    let account_scoped = path.starts_with(&format!("/{{{ACCOUNT_PARAM}}}/"));
    let last_segment = path
        .trim_end_matches(".json")
        .rsplit('/')
        .next()
        .unwrap_or_default();
    let mut params = Vec::new();
    for parameter in parameters_in(operation, "path") {
        let wire_name = parameter["name"]
            .as_str()
            .ok_or("path parameter without a name")?
            .to_string();
        if wire_name == ACCOUNT_PARAM {
            if !account_scoped {
                return Err(format!(
                    "{path} takes {ACCOUNT_PARAM} somewhere other than its first segment"
                ));
            }
            continue;
        }
        let role = if last_segment == format!("{{{wire_name}}}") {
            ParamRole::Recording
        } else {
            ParamRole::Parent
        };
        params.push(PathParam {
            wire_name,
            kind: param_kind(parameter, &parameter["schema"])?,
            role,
        });
    }
    Ok((account_scoped, params))
}

fn query_params(operation: &Value) -> Result<Vec<QueryParam>, String> {
    let mut params = Vec::new();
    for parameter in parameters_in(operation, "query") {
        let wire_name = parameter["name"]
            .as_str()
            .ok_or("query parameter without a name")?
            .to_string();
        let schema = &parameter["schema"];
        let (kind, list) = if schema["type"].as_str() == Some("array") {
            if parameter["style"]
                .as_str()
                .is_some_and(|style| style != "form")
                || parameter["explode"].as_bool() == Some(false)
            {
                return Err(format!(
                    "query parameter {wire_name}: only form/explode array serialization is supported"
                ));
            }
            (param_kind(parameter, &schema["items"])?, true)
        } else {
            (param_kind(parameter, schema)?, false)
        };
        params.push(QueryParam {
            wire_name,
            kind,
            list,
            required: parameter["required"].as_bool().unwrap_or(false),
        });
    }
    Ok(params)
}

fn parameters_in<'a>(operation: &'a Value, location: &'a str) -> impl Iterator<Item = &'a Value> {
    operation["parameters"]
        .as_array()
        .into_iter()
        .flatten()
        .filter(move |parameter| parameter["in"].as_str() == Some(location))
}

fn param_kind(parameter: &Value, schema: &Value) -> Result<ParamKind, String> {
    match (schema["type"].as_str(), schema["format"].as_str()) {
        (Some("string"), _) => Ok(ParamKind::String),
        (Some("boolean"), _) => Ok(ParamKind::Bool),
        (Some("integer"), Some("int32")) => Ok(ParamKind::Int32),
        (Some("integer"), _) => Ok(ParamKind::Int64),
        other => Err(format!(
            "parameter {}: unsupported type {other:?}",
            parameter["name"]
        )),
    }
}

fn body_of(operation: &Value, naming: &Naming) -> Option<String> {
    operation["requestBody"]["content"]["application/json"]["schema"]["$ref"]
        .as_str()
        .map(|reference| naming.type_for(&reference_name(reference)))
}

fn response_of(operation: &Value, naming: &Naming, schemas: &[Schema]) -> Result<Response, String> {
    let responses = operation["responses"]
        .as_object()
        .ok_or("operation has no responses")?;
    for (status, response) in responses {
        if status.starts_with('2') {
            return Ok(
                match response["content"]["application/json"]["schema"]["$ref"].as_str() {
                    Some(reference) => {
                        let schema = naming.type_for(&reference_name(reference));
                        let rust_type =
                            match schemas.iter().find(|candidate| candidate.name == schema) {
                                Some(Schema {
                                    shape: Shape::Alias(kind),
                                    ..
                                }) => crate::emit::types::rust_type(kind, false),
                                Some(_) => schema.clone(),
                                None => {
                                    return Err(format!(
                                        "{} answers unknown schema {schema}",
                                        operation["operationId"]
                                    ));
                                }
                            };
                        Response::Json(ResponseType { schema, rust_type })
                    }
                    None => Response::Empty,
                },
            );
        }
    }
    Err(format!("{} has no 2xx response", operation["operationId"]))
}

/// Whether the operation may be resent: `x-fizzy-idempotent` when the model says, the
/// behavior model's `idempotent` when it says, and otherwise what the method implies.
fn idempotent(http_method: &str, operation: &Value, semantics: &Value) -> bool {
    operation["x-fizzy-idempotent"]["natural"]
        .as_bool()
        .or(semantics["idempotent"].as_bool())
        .unwrap_or(matches!(http_method, "get" | "head" | "put" | "delete"))
}

fn pagination(semantics: &Value, id: &str) -> Result<Option<String>, String> {
    let pagination = &semantics["pagination"];
    match pagination["style"].as_str() {
        None => Ok(None),
        Some("link") => Ok(Some(
            pagination["page_param"]
                .as_str()
                .ok_or(format!("{id}: link pagination without a page_param"))?
                .to_string(),
        )),
        Some(other) => Err(format!("{id}: unsupported pagination style {other}")),
    }
}

/// The retry budget. `max` counts attempts, so `1` with no `retry_on` is an operation that
/// is never resent; anything else names the statuses it is resent on.
fn retry(semantics: &Value, id: &str) -> Result<Option<Retry>, String> {
    let retry = &semantics["retry"];
    let max = retry["max"]
        .as_u64()
        .ok_or(format!("{id}: retry.max is missing"))?;
    let max = u32::try_from(max).map_err(|_| format!("{id}: retry.max {max} is out of range"))?;
    let retry_on: Vec<u16> = retry["retry_on"]
        .as_array()
        .map(|codes| {
            codes
                .iter()
                .filter_map(Value::as_u64)
                .filter_map(|code| u16::try_from(code).ok())
                .collect()
        })
        .unwrap_or_default();
    if max <= 1 || retry_on.is_empty() {
        Ok(None)
    } else {
        Ok(Some(Retry {
            max,
            base_delay_ms: retry["base_delay_ms"].as_u64().unwrap_or(1000),
            retry_on,
        }))
    }
}

/// The behavior model's redaction map names Smithy shapes (`CreateSessionInput`) rather than
/// the schemas OpenAPI emits (`CreateSessionRequestContent`). Every entry has to land on a
/// field the generator already treats as sensitive, or the map and the code disagree.
fn verify_redaction(behavior: &Value, schemas: &[Schema]) -> Result<(), String> {
    for (shape, entries) in behavior["redaction"].as_object().into_iter().flatten() {
        let name = shape
            .strip_suffix("Input")
            .map(|stem| format!("{stem}RequestContent"))
            .or_else(|| {
                shape
                    .strip_suffix("Output")
                    .map(|stem| format!("{stem}ResponseContent"))
            })
            .unwrap_or_else(|| shape.clone());
        let schema = schemas
            .iter()
            .find(|schema| schema.name == name)
            .ok_or(format!("redaction names {shape}, which is not a schema"))?;
        for entry in entries.as_array().into_iter().flatten() {
            let path = entry["path"].as_str().unwrap_or_default();
            let field = path.strip_prefix("$.").unwrap_or(path);
            let sensitive = match &schema.shape {
                Shape::Struct(shape) => shape.fields.iter().any(|candidate| {
                    candidate.wire_name == field && candidate.kind == FieldType::SensitiveString
                }),
                Shape::Alias(_) => false,
            };
            if !sensitive {
                return Err(format!(
                    "redaction names {shape} {path}, which the generator does not treat as sensitive"
                ));
            }
        }
    }
    Ok(())
}

fn reference_name(reference: &str) -> String {
    reference
        .trim_start_matches("#/components/schemas/")
        .to_string()
}

impl FieldType {
    fn mentions(&self, schema: &str) -> bool {
        match self {
            FieldType::Named(name) => name == schema,
            FieldType::List(inner) | FieldType::Map(inner) => inner.mentions(schema),
            _ => false,
        }
    }
}

impl Schema {
    /// The fields the generator treats as sensitive, by wire name.
    pub fn sensitive_fields(&self) -> Vec<&str> {
        match &self.shape {
            Shape::Struct(shape) => shape
                .fields
                .iter()
                .filter(|field| field.kind == FieldType::SensitiveString)
                .map(|field| field.wire_name.as_str())
                .collect(),
            Shape::Alias(_) => Vec::new(),
        }
    }
}
