//! `services/*.rs`: one struct per service, one method per operation.

use std::fmt::Write;

use crate::emit::{HEADER, doc_comment, operation_doc};
use crate::model::{Model, Operation, ParamKind, ParamRole, PathParam, Response, Service};
use crate::naming::{constant_name, field_ident, service_label, struct_name};

/// Renders `services/mod.rs`.
pub fn render_mod(model: &Model) -> String {
    let mut out = String::from(HEADER);
    for service in &model.services {
        let _ = writeln!(
            out,
            "/// The `{}` operations.\npub mod {};",
            service_label(&service.name),
            service.name
        );
    }
    out
}

/// Renders one service file.
pub fn render_service(service: &Service) -> String {
    let name = struct_name(&service.name);
    let mut out = String::from(HEADER);
    out.push_str("use crate::client::Scope;\n");
    out.push_str("use crate::error::Error;\n");
    out.push_str("use crate::generated::routes;\n");
    if service.operations.iter().any(uses_types) {
        out.push_str("use crate::generated::types::*;\n");
    }
    if service
        .operations
        .iter()
        .any(|operation| operation.page_param.is_some())
    {
        out.push_str("use crate::pagination::Page;\n");
    }
    out.push('\n');

    for operation in &service.operations {
        render_params(&mut out, operation);
    }

    let _ = writeln!(
        out,
        "/// The `{}` operations.",
        service_label(&service.name)
    );
    let _ = writeln!(out, "pub struct {name}<'a> {{");
    out.push_str("    scope: Scope<'a>,\n}\n\n");
    let _ = writeln!(out, "impl<'a> {name}<'a> {{");
    out.push_str(
        "    pub(crate) fn new(scope: Scope<'a>) -> Self {\n        Self { scope }\n    }\n\n",
    );
    out.push_str("    /// The client and account these operations send through.\n");
    out.push_str("    pub fn scope(&self) -> &Scope<'a> {\n        &self.scope\n    }\n\n");
    for operation in &service.operations {
        render_method(&mut out, operation);
    }
    out.push_str("}\n");
    out
}

fn render_params(out: &mut String, operation: &Operation) {
    let optional: Vec<_> = operation
        .query_params
        .iter()
        .filter(|param| !param.required)
        .collect();
    if optional.is_empty() {
        return;
    }
    let _ = writeln!(out, "/// Optional query parameters for `{}`.", operation.id);
    out.push_str("#[derive(Debug, Clone, Default, PartialEq)]\n");
    let _ = writeln!(out, "pub struct {}Params {{", operation.id);
    for param in optional {
        let _ = writeln!(out, "    /// `{}`.", param.wire_name);
        let kind = owned_type(param.kind);
        let kind = if param.list {
            format!("Vec<{kind}>")
        } else {
            kind.to_string()
        };
        let _ = writeln!(
            out,
            "    pub {}: Option<{kind}>,",
            field_ident(&param.wire_name)
        );
    }
    out.push_str("}\n\n");
}

fn render_method(out: &mut String, operation: &Operation) {
    let mut arguments = vec!["&self".to_string()];
    for param in &operation.path_params {
        arguments.push(format!(
            "{}: {}",
            field_ident(&param.wire_name),
            borrowed_type(param.kind)
        ));
    }
    for param in operation.query_params.iter().filter(|param| param.required) {
        let kind = borrowed_type(param.kind);
        let kind = if param.list {
            format!("&[{}]", owned_type(param.kind))
        } else {
            kind.to_string()
        };
        arguments.push(format!("{}: {kind}", field_ident(&param.wire_name)));
    }
    let has_params = operation.query_params.iter().any(|param| !param.required);
    if has_params {
        arguments.push(format!("params: &{}Params", operation.id));
    }
    if let Some(body) = &operation.body {
        arguments.push(format!("body: &{body}"));
    }

    out.push_str(&doc_comment(&operation_doc(operation), "    "));
    let _ = writeln!(
        out,
        "    pub async fn {}({}) -> Result<{}, Error> {{",
        operation.method_name,
        arguments.join(", "),
        return_type(operation)
    );

    let path_arguments: Vec<String> = operation
        .path_params
        .iter()
        .map(|param| format!("&{}", field_ident(&param.wire_name)))
        .collect();
    let named_record = named_record(operation);
    let binding = if operation.query_params.is_empty()
        && operation.body.is_none()
        && named_record.is_none()
    {
        "let"
    } else {
        "let mut"
    };
    let _ = writeln!(
        out,
        "        {binding} operation = self.scope.operation(&routes::{}, &[{}])?;",
        constant_name(&operation.id),
        path_arguments.join(", ")
    );
    if let Some(param) = named_record {
        let _ = writeln!(
            out,
            "        operation.resource_id({});",
            field_ident(&param.wire_name)
        );
    }
    for param in &operation.query_params {
        let ident = field_ident(&param.wire_name);
        let _ = match (param.required, param.list) {
            (true, false) => writeln!(
                out,
                "        operation.query(\"{}\", {ident});",
                param.wire_name
            ),
            (true, true) => writeln!(
                out,
                "        operation.query_all(\"{}\", {ident});",
                param.wire_name
            ),
            (false, false) => writeln!(
                out,
                "        operation.query_optional(\"{}\", params.{ident}.as_ref());",
                param.wire_name
            ),
            (false, true) => writeln!(
                out,
                "        operation.query_all_optional(\"{}\", params.{ident}.as_deref());",
                param.wire_name
            ),
        };
    }
    if operation.body.is_some() {
        out.push_str("        operation.json(body)?;\n");
    }
    let _ = writeln!(
        out,
        "        self.scope.client().{}(operation).await",
        send_method(operation)
    );
    out.push_str("    }\n\n");
}

/// The path parameter that names the record the operation acts on: the id in the last
/// segment when the path ends in one, and otherwise the outermost parent's.
fn named_record(operation: &Operation) -> Option<&PathParam> {
    operation
        .path_params
        .iter()
        .find(|param| param.role == ParamRole::Recording)
        .or_else(|| operation.path_params.first())
}

fn uses_types(operation: &Operation) -> bool {
    operation.body.is_some() || matches!(operation.response, Response::Json(_))
}

fn return_type(operation: &Operation) -> String {
    match (&operation.response, operation.page_param.is_some()) {
        (Response::Empty, _) => "()".into(),
        (Response::Json(response), true) => format!("Page<{}>", response.rust_type),
        (Response::Json(response), false) => response.rust_type.clone(),
    }
}

fn send_method(operation: &Operation) -> &'static str {
    match (&operation.response, operation.page_param.is_some()) {
        (Response::Empty, _) => "send_unit",
        (Response::Json(_), true) => "send_page",
        (Response::Json(_), false) => "send",
    }
}

fn owned_type(kind: ParamKind) -> &'static str {
    match kind {
        ParamKind::String => "String",
        ParamKind::Bool => "bool",
        ParamKind::Int32 => "i32",
        ParamKind::Int64 => "i64",
    }
}

fn borrowed_type(kind: ParamKind) -> &'static str {
    match kind {
        ParamKind::String => "&str",
        ParamKind::Bool => "bool",
        ParamKind::Int32 => "i32",
        ParamKind::Int64 => "i64",
    }
}
