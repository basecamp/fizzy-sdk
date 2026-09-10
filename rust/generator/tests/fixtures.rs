//! The generator against small models with known answers. A drift check only proves the
//! checked-in code matches the generator; these prove the generator is right about the
//! shapes that matter — sensitive fields, recursion, required-vs-optional, array query
//! parameters, the account split, retry and pagination facts — and that it refuses what it
//! should. Set `UPDATE_FIXTURES=1` to rewrite the expected output after a deliberate change.

#![allow(clippy::unwrap_used, missing_docs)]

use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};

use fizzy_sdk_generator::model::{Model, ResourceTypes};
use fizzy_sdk_generator::naming::Naming;
use fizzy_sdk_generator::{format, render_inputs, write_all};

/// One scratch directory per generation, so parallel tests never share one.
static RUNS: std::sync::atomic::AtomicUsize = std::sync::atomic::AtomicUsize::new(0);

fn fixture(name: &str) -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("tests/fixtures")
        .join(name)
}

/// The generator's output for a fixture, formatted the way the checked-in code is.
fn generate(name: &str) -> BTreeMap<PathBuf, String> {
    let dir = fixture(name);
    let files = render_inputs(
        &dir.join("openapi.json"),
        &dir.join("behavior-model.json"),
        &dir.join("names.toml"),
    )
    .unwrap();
    let run = RUNS.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
    let scratch = std::env::temp_dir().join(format!(
        "fizzy-sdk-generator-fixture-{name}-{}-{run}",
        std::process::id()
    ));
    let paths = write_all(&scratch, &files).unwrap();
    format(&paths).unwrap();
    let formatted = files
        .keys()
        .map(|relative| {
            (
                relative.clone(),
                fs::read_to_string(scratch.join(relative)).unwrap(),
            )
        })
        .collect();
    let _ = fs::remove_dir_all(&scratch);
    formatted
}

fn list(root: &Path, directory: &Path, into: &mut Vec<PathBuf>) {
    for entry in fs::read_dir(directory).into_iter().flatten().flatten() {
        let path = entry.path();
        if path.is_dir() {
            list(root, &path, into);
        } else {
            into.push(path.strip_prefix(root).unwrap().to_path_buf());
        }
    }
}

#[test]
fn the_mini_model_renders_as_expected() {
    let files = generate("mini");
    let expected_dir = fixture("mini").join("expected");
    if std::env::var_os("UPDATE_FIXTURES").is_some() {
        let _ = fs::remove_dir_all(&expected_dir);
        write_all(&expected_dir, &files).unwrap();
        return;
    }
    let mut mismatched = Vec::new();
    for (relative, content) in &files {
        let expected = fs::read_to_string(expected_dir.join(relative)).unwrap_or_default();
        if &expected != content {
            mismatched.push(relative.display().to_string());
        }
    }
    let mut existing = Vec::new();
    list(&expected_dir, &expected_dir, &mut existing);
    for relative in existing {
        if !files.contains_key(&relative) {
            mismatched.push(format!("{} (no longer generated)", relative.display()));
        }
    }
    assert!(
        mismatched.is_empty(),
        "generated output differs from tests/fixtures/mini/expected for:\n  {}\nrun with UPDATE_FIXTURES=1 after checking the diff is intended",
        mismatched.join("\n  ")
    );
}

#[test]
fn the_mini_model_says_what_it_should() {
    let files = generate("mini");
    let types = &files[Path::new("src/generated/types.rs")];
    let routes = &files[Path::new("src/generated/routes.rs")];
    let widgets = &files[Path::new("src/generated/services/widgets.rs")];
    let sessions = &files[Path::new("src/generated/services/sessions.rs")];
    let accessors = &files[Path::new("src/generated/accessors.rs")];
    let redaction = &files[Path::new("src/generated/redaction.rs")];

    // Sensitive strings from both spellings; a recursive field boxed; a keyword escaped; a
    // required timestamp without a default; a request type open to construction and a
    // response type closed.
    assert!(types.contains("pub email_address: SensitiveString,"));
    assert!(types.contains("pub owner_name: Option<SensitiveString>,"));
    assert!(types.contains("pub parent: Option<::std::boxed::Box<Widget>>,"));
    assert!(types.contains("pub r#type: Option<String>,"));
    assert!(types.contains("pub created_at: DateTime,"));
    assert!(types.contains("pub extra: Option<BTreeMap<String, String>>,"));
    assert!(types.contains("#[non_exhaustive]\npub struct Widget {"));
    assert!(!types.contains("#[non_exhaustive]\npub struct CreateSessionRequestContent {"));
    assert!(types.contains("pub type ListWidgetsResponseContent = Vec<Widget>;"));

    // Routes carry the account split, the retry budget and the page parameter.
    assert!(routes.contains("retry: None,"));
    assert!(routes.contains("retry_on: &[429, 500, 503],"));
    assert!(routes.contains("pagination: Pagination::Link { page_param: \"page\" },"));
    assert!(routes.contains("account_scoped: true,"));
    assert!(routes.contains("kind: ParamKind::Int32"));

    // Services: array and scalar query parameters, typed path parameters, resolved response
    // types, and the accessor split.
    assert!(widgets.contains("pub tag_ids: Option<Vec<String>>,"));
    assert!(
        widgets.contains("operation.query_all_optional(\"tag_ids[]\", params.tag_ids.as_deref());")
    );
    assert!(widgets.contains(
        "pub async fn get(&self, widget_number: i32, expand: bool) -> Result<Widget, Error>"
    ));
    assert!(widgets.contains("Result<Page<Vec<Widget>>, Error>"));
    assert!(widgets.contains("pub async fn close(&self, widget_number: i32) -> Result<(), Error>"));
    assert!(sessions.contains("body: &CreateSessionRequestContent,"));
    assert!(
        accessors
            .contains("impl Client {\n    /// The `Sessions` operations that need no account.")
    );
    assert!(accessors.contains(
        "impl AccountClient {\n    /// The `Widgets` operations, scoped to this account."
    ));
    assert!(!accessors[..accessors.find("impl AccountClient").unwrap()].contains("widgets"));

    // Every sensitive field, whichever spelling marked it, is in the redaction table.
    assert!(redaction.contains("(\"CreateSessionRequestContent\", &[\"$.email_address\"]),"));
    assert!(redaction.contains("(\"Widget\", &[\"$.owner_name\"]),"));
}

fn build(openapi: &str, behavior: &str, names: &str) -> Result<Model, String> {
    let openapi = serde_json::from_str(openapi).unwrap();
    let behavior = serde_json::from_str(behavior).unwrap();
    Model::build(
        &openapi,
        &behavior,
        &Naming::parse(names).unwrap(),
        &ResourceTypes::parse(names).unwrap(),
    )
}

const WIDGET_GET: &str = r##"{
  "info": {"version": "1"},
  "paths": {"/{accountId}/widgets/{id}": {"get": {"operationId": "GetWidget",
    "parameters": [{"name": "accountId", "in": "path", "schema": {"type": "string"}}, {"name": "id", "in": "path", "schema": {"type": "string"}}],
    "responses": {"200": {"content": {"application/json": {"schema": {"$ref": "#/components/schemas/Widget"}}}}}}}},
  "components": {"schemas": {"Widget": {"type": "object", "properties": {"id": {"type": "string"}}}}}
}"##;
const WIDGET_BEHAVIOR: &str = r#"{"operations": {"GetWidget": {"retry": {"max": 1}}}}"#;
const WIDGET_NAMES: &str = "service_suffixes = [{ suffix = \"Widget\", service = \"widgets\" }]\n[resource_types]\nwidgets = \"widget\"\n";

#[test]
fn an_operation_no_rule_covers_fails_generation() {
    let error = build(
        WIDGET_GET,
        WIDGET_BEHAVIOR,
        "[resource_types]\nwidgets = \"widget\"\n",
    )
    .err()
    .unwrap();
    assert!(
        error.contains("cannot derive a service for GetWidget"),
        "{error}"
    );
}

#[test]
fn a_service_without_a_resource_type_fails_generation() {
    let error = build(
        WIDGET_GET,
        WIDGET_BEHAVIOR,
        "service_suffixes = [{ suffix = \"Widget\", service = \"widgets\" }]\n",
    )
    .err()
    .unwrap();
    assert!(error.contains("widgets has no resource type"), "{error}");
}

#[test]
fn an_operation_missing_from_the_behavior_model_fails_generation() {
    let error = build(WIDGET_GET, r#"{"operations": {}}"#, WIDGET_NAMES)
        .err()
        .unwrap();
    assert!(
        error.contains("GetWidget is missing from behavior-model.json"),
        "{error}"
    );
}

#[test]
fn a_redaction_entry_the_generator_does_not_treat_as_sensitive_fails_generation() {
    let behavior = r#"{"operations": {"GetWidget": {"retry": {"max": 1}}}, "redaction": {"Widget": [{"path": "$.id"}]}}"#;
    let error = build(WIDGET_GET, behavior, WIDGET_NAMES).err().unwrap();
    assert!(error.contains("redaction names Widget $.id"), "{error}");
}

#[test]
fn two_operations_landing_on_one_method_fail_generation() {
    let openapi = WIDGET_GET.replace(
        r#""/{accountId}/widgets/{id}": {"get""#,
        r##""/{accountId}/widgets/{id}.json": {"get": {"operationId": "GetWidgetJson", "parameters": [{"name": "accountId", "in": "path", "schema": {"type": "string"}}, {"name": "id", "in": "path", "schema": {"type": "string"}}], "responses": {"200": {"content": {"application/json": {"schema": {"$ref": "#/components/schemas/Widget"}}}}}}}, "/{accountId}/widgets/{id}": {"get""##,
    );
    let behavior = r#"{"operations": {"GetWidget": {"retry": {"max": 1}}, "GetWidgetJson": {"retry": {"max": 1}}}}"#;
    let names = "service_suffixes = [{ suffix = \"WidgetJson\", service = \"widgets\" }, { suffix = \"Widget\", service = \"widgets\" }]\n[operation_methods]\nGetWidgetJson = \"get\"\n[resource_types]\nwidgets = \"widget\"\n";
    let error = build(&openapi, behavior, names).err().unwrap();
    assert!(error.contains("both become widgets::get"), "{error}");
}

#[test]
fn an_unsupported_query_serialization_fails_generation() {
    let openapi = WIDGET_GET.replace(
        r#"{"name": "id", "in": "path", "schema": {"type": "string"}}"#,
        r#"{"name": "id", "in": "path", "schema": {"type": "string"}}, {"name": "ids", "in": "query", "explode": false, "schema": {"type": "array", "items": {"type": "string"}}}"#,
    );
    let error = build(&openapi, WIDGET_BEHAVIOR, WIDGET_NAMES)
        .err()
        .unwrap();
    assert!(
        error.contains("only form/explode array serialization is supported"),
        "{error}"
    );
}

#[test]
fn a_keyword_method_name_fails_generation() {
    let openapi = WIDGET_GET.replace("GetWidget", "MoveWidget");
    let behavior = WIDGET_BEHAVIOR.replace("GetWidget", "MoveWidget");
    let error = build(&openapi, &behavior, WIDGET_NAMES).err().unwrap();
    assert!(error.contains("MoveWidget becomes `move`"), "{error}");
}
