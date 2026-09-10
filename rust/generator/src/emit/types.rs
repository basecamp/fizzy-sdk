//! `types.rs`: one Rust type per schema.

use std::fmt::Write;

use crate::emit::{HEADER, doc_comment};
use crate::model::{FieldType, Model, Schema, Shape};
use crate::naming::field_ident;

/// Renders every schema.
pub fn render(model: &Model) -> String {
    let mut out = String::from(HEADER);
    out.push_str("use std::collections::BTreeMap;\n\n");
    out.push_str("use serde::{Deserialize, Serialize};\n\n");
    out.push_str("use crate::types::{DateTime, SensitiveString};\n\n");
    for schema in &model.schemas {
        render_schema(&mut out, schema);
    }
    out
}

fn render_schema(out: &mut String, schema: &Schema) {
    match &schema.shape {
        Shape::Alias(kind) => {
            out.push_str(&doc_comment(
                &format!("`{}`, as the model names it.", schema.name),
                "",
            ));
            let _ = writeln!(
                out,
                "pub type {} = {};\n",
                schema.name,
                rust_type(kind, false)
            );
        }
        Shape::Struct(shape) => {
            let doc = if schema.constructible {
                format!(
                    "`{}`. Built by hand, so it derives `Default` and takes `..Default::default()`.",
                    schema.name
                )
            } else {
                format!(
                    "`{}`, as Fizzy sends it. Read-only, so a field added later is not a breaking change.",
                    schema.name
                )
            };
            out.push_str(&doc_comment(&doc, ""));
            out.push_str("#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]\n");
            if !schema.constructible {
                out.push_str("#[non_exhaustive]\n");
            }
            let _ = writeln!(out, "pub struct {} {{", schema.name);
            for field in &shape.fields {
                out.push_str(&doc_comment(&format!("`{}`.", field.wire_name), "    "));
                let ident = field_ident(&field.wire_name);
                if ident.trim_start_matches("r#") != field.wire_name {
                    let _ = writeln!(out, "    #[serde(rename = \"{}\")]", field.wire_name);
                }
                let kind = rust_type(&field.kind, field.recursive);
                // A required field the server leaves out — or blanks with null — reads as
                // its zero value rather than failing the whole response, the way Go's
                // encoding/json reads it. A moment has no zero value worth having, so a
                // timestamp carries no default and a response missing one fails.
                if field.required {
                    match required_default(&field.kind) {
                        RequiredDefault::NullOrMissing => out.push_str("    #[serde(default, deserialize_with = \"crate::types::null_as_default::deserialize\")]\n"),
                        RequiredDefault::Missing => out.push_str("    #[serde(default)]\n"),
                        RequiredDefault::None => {}
                    }
                    let _ = writeln!(out, "    pub {ident}: {kind},");
                } else {
                    out.push_str(
                        "    #[serde(default, skip_serializing_if = \"Option::is_none\")]\n",
                    );
                    let _ = writeln!(out, "    pub {ident}: Option<{kind}>,");
                }
            }
            out.push_str("}\n\n");
        }
    }
}

/// How far a required field's absence is forgiven.
enum RequiredDefault {
    /// The type has a zero value, so both a missing field and an explicit `null` land on it.
    NullOrMissing,
    /// A missing field lands on the type's default; a `null` still fails.
    Missing,
    /// Neither is forgiven.
    None,
}

fn required_default(kind: &FieldType) -> RequiredDefault {
    match kind {
        FieldType::String
        | FieldType::SensitiveString
        | FieldType::Bool
        | FieldType::Int32
        | FieldType::Int64
        | FieldType::List(_)
        | FieldType::Map(_) => RequiredDefault::NullOrMissing,
        FieldType::DateTime => RequiredDefault::None,
        FieldType::Json | FieldType::Named(_) => RequiredDefault::Missing,
    }
}

/// The Rust spelling of a field type.
pub fn rust_type(kind: &FieldType, recursive: bool) -> String {
    match kind {
        FieldType::String => "String".into(),
        FieldType::SensitiveString => "SensitiveString".into(),
        FieldType::DateTime => "DateTime".into(),
        FieldType::Bool => "bool".into(),
        FieldType::Int32 => "i32".into(),
        FieldType::Int64 => "i64".into(),
        FieldType::Json => "serde_json::Value".into(),
        FieldType::Named(name) if recursive => format!("::std::boxed::Box<{name}>"),
        FieldType::Named(name) => name.clone(),
        FieldType::List(inner) => format!("Vec<{}>", rust_type(inner, false)),
        FieldType::Map(inner) => format!("BTreeMap<String, {}>", rust_type(inner, false)),
    }
}
