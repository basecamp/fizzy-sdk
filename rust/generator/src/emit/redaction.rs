//! `redaction.rs`: which fields of which types the hooks and logs must not see.

use std::fmt::Write;

use crate::emit::HEADER;
use crate::model::Model;

/// Renders the table of sensitive fields, by schema, as JSON paths.
pub fn render(model: &Model) -> String {
    let mut out = String::from(HEADER);
    out.push_str(
        "/// The fields the model marks sensitive, as JSON paths under each type. Every one is\n",
    );
    out.push_str("/// typed as [`SensitiveString`](crate::types::SensitiveString) and prints redacted; this\n");
    out.push_str("/// table is for anything that handles the JSON itself.\n");
    out.push_str("pub static PATHS: &[(&str, &[&str])] = &[\n");
    for schema in &model.schemas {
        let fields = schema.sensitive_fields();
        if fields.is_empty() {
            continue;
        }
        let paths: Vec<String> = fields
            .iter()
            .map(|field| format!("\"$.{field}\""))
            .collect();
        let _ = writeln!(out, "    (\"{}\", &[{}]),", schema.name, paths.join(", "));
    }
    out.push_str("];\n");
    out
}
