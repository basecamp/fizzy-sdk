//! `accessors.rs`: the service handles on `Client` and `AccountClient`.

use std::fmt::Write;

use crate::emit::HEADER;
use crate::model::Model;
use crate::naming::{service_label, struct_name};

/// Renders the accessor impls.
pub fn render(model: &Model) -> String {
    let mut out = String::from(HEADER);
    out.push_str("use crate::client::{AccountClient, Client};\n");
    out.push_str("use crate::generated::services;\n\n");

    out.push_str("impl Client {\n");
    for service in model.services.iter().filter(|service| service.on_client()) {
        let name = struct_name(&service.name);
        let _ = writeln!(
            out,
            "    /// The `{}` operations that need no account.\n    pub fn {}(&self) -> services::{}::{name}<'_> {{\n        services::{}::{name}::new(self.scope())\n    }}\n",
            service_label(&service.name),
            service.name,
            service.name,
            service.name
        );
    }
    out.push_str("}\n\n");

    out.push_str("impl AccountClient {\n");
    for service in model.services.iter().filter(|service| service.on_account()) {
        let name = struct_name(&service.name);
        let _ = writeln!(
            out,
            "    /// The `{}` operations, scoped to this account.\n    pub fn {}(&self) -> services::{}::{name}<'_> {{\n        services::{}::{name}::new(self.scope())\n    }}\n",
            service_label(&service.name),
            service.name,
            service.name,
            service.name
        );
    }
    out.push_str("}\n");
    out
}
