//! `tests/generated_calls/*.rs`: one wiremock test per operation, proving the generated
//! method builds the path the model names, serializes its body and query the way the wire
//! expects, and decodes a schema-valid answer. The generic conformance runner sends
//! fixture-authored paths and bodies, so it proves the transport and nothing about these.

use std::fmt::Write;

use crate::emit::HEADER;
use crate::model::{Model, Operation, ParamKind, Response, Service};
use crate::naming::field_ident;

/// The account every account-scoped test sends under.
const ACCOUNT: &str = "999";

/// Renders `main.rs`: the module list and the client every test builds.
pub fn render_main(model: &Model) -> String {
    let mut out = String::from(HEADER);
    out.push_str("#![cfg(feature = \"reqwest\")]\n#![allow(clippy::pedantic, clippy::unwrap_used, missing_docs)]\n\n");
    for service in &model.services {
        let _ = writeln!(out, "mod {};", service.name);
    }
    out.push_str("\nuse std::time::Duration;\n\n");
    out.push_str("use fizzy_sdk::{Client, Config};\nuse wiremock::MockServer;\n\n");
    out.push_str("/// A client pointed at the mock server, with retries wound down so a failing test\n/// fails fast.\n");
    out.push_str("fn client(server: &MockServer) -> Client {\n");
    out.push_str("    Client::builder(Config::default().with_base_url(server.uri()))\n");
    out.push_str("        .access_token(\"test-token\")\n");
    out.push_str("        .max_attempts(1)\n");
    out.push_str("        .max_jitter(Duration::ZERO)\n");
    out.push_str("        .build()\n        .unwrap()\n}\n");
    out
}

/// Renders one service's tests.
pub fn render_service(service: &Service) -> String {
    let mut out = String::from(HEADER);
    if service.operations.iter().any(|operation| {
        operation.body.is_some() || matches!(operation.response, Response::Json(_))
    }) {
        out.push_str("use fizzy_sdk::models::*;\n");
    }
    if service
        .operations
        .iter()
        .any(|operation| operation.query_params.iter().any(|param| !param.required))
    {
        let _ = writeln!(out, "use fizzy_sdk::services::{}::*;", service.name);
    }
    let mut matchers = vec!["method", "path"];
    if service
        .operations
        .iter()
        .any(|operation| operation.body.is_some())
    {
        matchers.insert(0, "body_json");
    }
    if service
        .operations
        .iter()
        .any(|operation| !operation.query_params.is_empty())
    {
        matchers.push("query_param");
    }
    let _ = writeln!(out, "use wiremock::matchers::{{{}}};", matchers.join(", "));
    out.push_str("use wiremock::{Mock, MockServer, ResponseTemplate};\n\n");
    out.push_str("use crate::client;\n\n");
    for operation in &service.operations {
        render_test(&mut out, service, operation);
    }
    out
}

fn render_test(out: &mut String, service: &Service, operation: &Operation) {
    let _ = writeln!(out, "/// `{}`.", operation.id);
    out.push_str("#[tokio::test]\n");
    let _ = writeln!(out, "async fn {}() {{", operation.method_name);
    out.push_str("    let server = MockServer::start().await;\n");

    let (status, expected_type) = match &operation.response {
        Response::Empty => (204, None),
        Response::Json(response) => (200, Some(response.rust_type.as_str())),
    };
    if let Some(expected_type) = expected_type {
        let _ = writeln!(
            out,
            "    let expected: {expected_type} = Default::default();"
        );
    }
    if let Some(body) = &operation.body {
        let _ = writeln!(out, "    let body = {body}::default();");
    }
    let optional: Vec<_> = operation
        .query_params
        .iter()
        .filter(|param| !param.required)
        .collect();
    if !optional.is_empty() {
        let _ = writeln!(out, "    let params = {}Params {{", operation.id);
        for param in &optional {
            let value = sample_query_argument(param.kind);
            let value = if param.list {
                format!("vec![{value}.into()]")
            } else if param.kind == ParamKind::String {
                format!("{value}.into()")
            } else {
                value
            };
            let _ = writeln!(
                out,
                "        {}: Some({value}),",
                field_ident(&param.wire_name)
            );
        }
        out.push_str("    };\n");
    }

    render_mock(out, operation, status, expected_type.is_some());

    let accessor = if operation.account_scoped {
        format!(
            "client(&server).for_account(\"{ACCOUNT}\").unwrap().{}()",
            service.name
        )
    } else {
        format!("client(&server).{}()", service.name)
    };
    let mut arguments = Vec::new();
    for param in &operation.path_params {
        arguments.push(sample_path_argument(param.kind, &param.wire_name));
    }
    for param in operation.query_params.iter().filter(|param| param.required) {
        arguments.push(if param.list {
            format!("&[{}]", sample_query_argument(param.kind))
        } else {
            sample_query_argument(param.kind)
        });
    }
    if !optional.is_empty() {
        arguments.push("&params".to_string());
    }
    if operation.body.is_some() {
        arguments.push("&body".to_string());
    }
    let binding = if expected_type.is_some() {
        "let answer = "
    } else {
        ""
    };
    let _ = writeln!(
        out,
        "    {binding}{accessor}\n        .{}({})\n        .await\n        .unwrap();",
        operation.method_name,
        arguments.join(", ")
    );
    match (expected_type, operation.page_param.is_some()) {
        (None, _) => {}
        (Some(_), true) => {
            out.push_str("    assert_eq!(answer.value(), &expected);\n");
            out.push_str("    assert!(!answer.has_next());\n");
        }
        (Some(_), false) => out.push_str("    assert_eq!(answer, expected);\n"),
    }
    out.push_str("    server.verify().await;\n}\n\n");
}

/// The mock every test mounts: the method and path the model names, every query parameter
/// with its sample value, the body when there is one, and the answer.
fn render_mock(out: &mut String, operation: &Operation, status: u16, answers_json: bool) {
    let _ = writeln!(
        out,
        "    Mock::given(method(\"{}\"))",
        operation.http_method
    );
    let _ = writeln!(out, "        .and(path(\"{}\"))", sample_path(operation));
    for param in &operation.query_params {
        let _ = writeln!(
            out,
            "        .and(query_param(\"{}\", \"{}\"))",
            param.wire_name,
            sample_query(param.kind)
        );
    }
    if operation.body.is_some() {
        out.push_str("        .and(body_json(serde_json::to_value(&body).unwrap()))\n");
    }
    if answers_json {
        let _ = writeln!(
            out,
            "        .respond_with(ResponseTemplate::new({status}).set_body_json(serde_json::to_value(&expected).unwrap()))"
        );
    } else {
        let _ = writeln!(
            out,
            "        .respond_with(ResponseTemplate::new({status}))"
        );
    }
    out.push_str("        .expect(1)\n        .mount(&server)\n        .await;\n");
}

/// The path the request should land on, with a sample value for every parameter.
fn sample_path(operation: &Operation) -> String {
    let mut path = operation.path.clone();
    if operation.account_scoped {
        path = path.replace("{accountId}", ACCOUNT);
    }
    for param in &operation.path_params {
        path = path.replace(
            &format!("{{{}}}", param.wire_name),
            &sample_path_value(param.kind, &param.wire_name),
        );
    }
    path
}

fn sample_path_value(kind: ParamKind, name: &str) -> String {
    match kind {
        ParamKind::String => format!("x-{}", field_ident(name)),
        ParamKind::Bool => "true".into(),
        ParamKind::Int32 | ParamKind::Int64 => "7".into(),
    }
}

fn sample_path_argument(kind: ParamKind, name: &str) -> String {
    match kind {
        ParamKind::String => format!("\"{}\"", sample_path_value(kind, name)),
        _ => sample_path_value(kind, name),
    }
}

fn sample_query(kind: ParamKind) -> &'static str {
    match kind {
        ParamKind::String => "x",
        ParamKind::Bool => "true",
        ParamKind::Int32 | ParamKind::Int64 => "7",
    }
}

fn sample_query_argument(kind: ParamKind) -> String {
    match kind {
        ParamKind::String => "\"x\"".into(),
        ParamKind::Bool => "true".into(),
        ParamKind::Int32 | ParamKind::Int64 => "7".into(),
    }
}
