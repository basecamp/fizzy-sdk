//! `routes.rs`: one `Route` static per operation, and the table of all of them.

use std::fmt::Write;

use crate::emit::{HEADER, doc_comment, operation_doc};
use crate::model::{Model, Operation, ParamKind, ParamRole};
use crate::naming::constant_name;

/// Renders the route table.
pub fn render(model: &Model) -> String {
    let mut out = String::from(HEADER);
    out.push_str("use crate::http::Method;\n");
    out.push_str(
        "use crate::route::{Pagination, ParamKind, ParamRole, Retry, Route, RouteParam};\n\n",
    );

    let operations = model.operations();
    for operation in &operations {
        render_route(&mut out, operation);
    }

    out.push_str("/// Every route the SDK knows, one per operation, by operation id.\n");
    out.push_str("pub static ROUTES: &[&Route] = &[\n");
    for operation in &operations {
        let _ = writeln!(out, "    &{},", constant_name(&operation.id));
    }
    out.push_str("];\n");
    out
}

fn render_route(out: &mut String, operation: &Operation) {
    let pattern = operation.path.trim_end_matches(".json");
    out.push_str(&doc_comment(&operation_doc(operation), ""));
    let _ = writeln!(
        out,
        "pub static {}: Route = Route {{",
        constant_name(&operation.id)
    );
    let _ = writeln!(out, "    id: \"{}\",", operation.id);
    let _ = writeln!(out, "    service: \"{}\",", operation.service);
    let _ = writeln!(out, "    method: Method::{},", operation.http_method);
    let _ = writeln!(out, "    path: \"{}\",", operation.path);
    let _ = writeln!(out, "    pattern: \"{pattern}\",");
    let _ = writeln!(out, "    account_scoped: {},", operation.account_scoped);
    let _ = writeln!(out, "    resource_type: \"{}\",", operation.resource_type);
    out.push_str("    params: &[\n");
    for param in &operation.path_params {
        let _ = writeln!(
            out,
            "        RouteParam {{ name: \"{}\", role: ParamRole::{}, kind: ParamKind::{} }},",
            param.wire_name,
            param_role(param.role),
            param_kind(param.kind)
        );
    }
    out.push_str("    ],\n");
    let _ = writeln!(out, "    idempotent: {},", operation.idempotent);
    let _ = writeln!(out, "    readonly: {},", operation.readonly);
    match &operation.page_param {
        Some(page_param) => {
            let _ = writeln!(
                out,
                "    pagination: Pagination::Link {{ page_param: \"{page_param}\" }},"
            );
        }
        None => out.push_str("    pagination: Pagination::None,\n"),
    }
    match &operation.retry {
        Some(retry) => {
            let _ = writeln!(
                out,
                "    retry: Some(Retry {{ max: {}, base_delay_ms: {}, retry_on: &{:?} }}),",
                retry.max, retry.base_delay_ms, retry.retry_on
            );
        }
        None => out.push_str("    retry: None,\n"),
    }
    out.push_str("};\n\n");
}

fn param_role(role: ParamRole) -> &'static str {
    match role {
        ParamRole::Parent => "Parent",
        ParamRole::Recording => "Recording",
    }
}

fn param_kind(kind: ParamKind) -> &'static str {
    match kind {
        ParamKind::String => "String",
        ParamKind::Bool => "Bool",
        ParamKind::Int32 => "Int32",
        ParamKind::Int64 => "Int64",
    }
}
