//! How the model's names become Rust names, and the overrides in `names.toml` that settle
//! what the rules alone cannot.

use std::collections::BTreeMap;

use heck::{ToPascalCase, ToSnakeCase};
use serde::Deserialize;

/// One rule of the service grouper: an operation id ending in `suffix` belongs to
/// `service`. Rules are tried in the order written, longest suffix first.
#[derive(Deserialize, Debug, Clone)]
pub struct SuffixRule {
    /// The end of the operation id.
    pub suffix: String,
    /// The snake_cased service it files under.
    pub service: String,
}

/// The naming overrides, read from `names.toml`.
#[derive(Deserialize, Default)]
pub struct Naming {
    #[serde(default)]
    service_suffixes: Vec<SuffixRule>,
    #[serde(default)]
    operation_services: BTreeMap<String, String>,
    #[serde(default)]
    operation_methods: BTreeMap<String, String>,
    #[serde(default)]
    type_names: BTreeMap<String, String>,
}

const KEYWORDS: &[&str] = &[
    "abstract", "as", "async", "await", "become", "box", "break", "const", "continue", "crate",
    "do", "dyn", "else", "enum", "extern", "false", "final", "fn", "for", "gen", "if", "impl",
    "in", "let", "loop", "macro", "match", "mod", "move", "mut", "override", "priv", "pub", "ref",
    "return", "self", "static", "struct", "super", "trait", "true", "try", "type", "typeof",
    "unsafe", "unsized", "use", "virtual", "where", "while", "yield",
];

impl Naming {
    /// Reads the overrides out of `names.toml`.
    pub fn parse(source: &str) -> Result<Naming, String> {
        toml::from_str(source).map_err(|error| format!("names.toml: {error}"))
    }

    /// The snake_cased service an operation files under. Fizzy's OpenAPI tags nothing, so
    /// the service comes from the operation id: an override in `[operation_services]`, else
    /// the first `[[service_suffixes]]` rule the id ends in. An id no rule covers fails
    /// generation rather than landing somewhere by accident.
    pub fn service_for(&self, operation_id: &str) -> Result<String, String> {
        if let Some(service) = self.operation_services.get(operation_id) {
            return Ok(service.clone());
        }
        self.service_suffixes
            .iter()
            .find(|rule| operation_id.ends_with(&rule.suffix))
            .map(|rule| rule.service.clone())
            .ok_or_else(|| {
                format!(
                    "cannot derive a service for {operation_id}; add it to [operation_services] or a [[service_suffixes]] rule in names.toml"
                )
            })
    }

    /// The method name for an operation: an override in `[operation_methods]`, else the
    /// operation id with the service's own noun removed (`ListBoards` -> `boards().list()`).
    pub fn method_for(&self, operation_id: &str, service: &str) -> Result<String, String> {
        if let Some(method) = self.operation_methods.get(operation_id) {
            return Ok(method.clone());
        }
        let service_words: Vec<String> = service.split('_').map(singular).collect();
        let words: Vec<String> = camel_words(operation_id)
            .into_iter()
            .map(|word| word.to_lowercase())
            .filter(|word| !service_words.contains(&singular(word)))
            .collect();
        let method = words.join("_");
        if method.is_empty() || KEYWORDS.contains(&method.as_str()) {
            Err(format!(
                "{operation_id} becomes `{method}` in {service}; add an [operation_methods] override to names.toml"
            ))
        } else {
            Ok(method)
        }
    }

    /// What a schema is called in Rust. A shape whose model name collides with something
    /// the language already has is renamed here; the wire is untouched, since a type name
    /// never serializes.
    pub fn type_for(&self, schema: &str) -> String {
        self.type_names
            .get(schema)
            .cloned()
            .unwrap_or_else(|| schema.to_string())
    }
}

/// The struct a service is: `boards` -> `BoardsService`, the name every Fizzy SDK gives it.
pub fn struct_name(service: &str) -> String {
    format!("{}Service", service.to_pascal_case())
}

/// The service as the hooks name it: `boards` -> `Boards`.
pub fn service_label(service: &str) -> String {
    service.to_pascal_case()
}

/// The Rust field for a wire name: snake_cased, brackets dropped (`column_ids[]` ->
/// `column_ids`), keywords escaped.
pub fn field_ident(wire_name: &str) -> String {
    let ident = wire_name
        .replace(['[', ']'], "_")
        .trim_end_matches('_')
        .to_snake_case();
    if KEYWORDS.contains(&ident.as_str()) {
        format!("r#{ident}")
    } else {
        ident
    }
}

/// The route constant for an operation: `ListBoards` -> `LIST_BOARDS`.
pub fn constant_name(operation_id: &str) -> String {
    operation_id.to_snake_case().to_uppercase()
}

fn camel_words(source: &str) -> Vec<String> {
    let mut words = Vec::new();
    let mut current = String::new();
    for character in source.chars() {
        if character.is_uppercase() && !current.is_empty() {
            words.push(std::mem::take(&mut current));
        }
        current.push(character);
    }
    if !current.is_empty() {
        words.push(current);
    }
    words
}

fn singular(word: &str) -> String {
    if let Some(stem) = word.strip_suffix("ies") {
        format!("{stem}y")
    } else if word.ends_with("ses")
        || word.ends_with("xes")
        || word.ends_with("ches")
        || word.ends_with("shes")
    {
        word[..word.len() - 2].to_string()
    } else if word.ends_with('s') && !word.ends_with("ss") {
        word[..word.len() - 1].to_string()
    } else {
        word.to_string()
    }
}

#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests {
    use super::*;

    #[test]
    fn methods_drop_the_service_noun() {
        let naming = Naming::default();
        assert_eq!(naming.method_for("ListBoards", "boards").unwrap(), "list");
        assert_eq!(naming.method_for("GetCard", "cards").unwrap(), "get");
        assert_eq!(
            naming.method_for("ListBoardAccesses", "boards").unwrap(),
            "list_accesses"
        );
        assert_eq!(
            naming
                .method_for("CreateAccessToken", "access_tokens")
                .unwrap(),
            "create"
        );
        assert_eq!(
            naming.method_for("MoveColumnLeft", "columns").unwrap(),
            "move_left"
        );
    }

    #[test]
    fn a_method_that_comes_out_empty_or_a_keyword_needs_an_override() {
        let naming = Naming::default();
        assert!(naming.method_for("Boards", "boards").is_err());
        assert!(naming.method_for("MoveCard", "cards").unwrap() == "move");
    }

    #[test]
    fn services_come_from_overrides_then_suffix_rules_in_order() {
        let naming = Naming::parse(
            r#"
            service_suffixes = [
                { suffix = "CardReaction", service = "reactions" },
                { suffix = "Card", service = "cards" },
            ]
            [operation_services]
            SearchCards = "search"
            "#,
        )
        .unwrap();

        assert_eq!(
            naming.service_for("CreateCardReaction").unwrap(),
            "reactions"
        );
        assert_eq!(naming.service_for("GetCard").unwrap(), "cards");
        assert_eq!(naming.service_for("SearchCards").unwrap(), "search");
        assert!(naming.service_for("ListTags").is_err());
    }

    #[test]
    fn type_names_are_the_models_own_unless_overridden() {
        let naming = Naming::parse("[type_names]\nBox = \"Mailbox\"\n").unwrap();

        assert_eq!(naming.type_for("Box"), "Mailbox");
        assert_eq!(naming.type_for("BoxGroup"), "BoxGroup");
        assert_eq!(Naming::default().type_for("Box"), "Box");
    }

    #[test]
    fn fields_escape_keywords_and_brackets() {
        assert_eq!(field_ident("type"), "r#type");
        assert_eq!(field_ident("boardId"), "board_id");
        assert_eq!(field_ident("column_ids[]"), "column_ids");
    }
}
