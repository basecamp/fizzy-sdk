use std::collections::BTreeMap;

use percent_encoding::{AsciiSet, CONTROLS, utf8_percent_encode};
use serde::Deserialize;
use serde_json::{Map, Value};

pub type Params = Map<String, Value>;

/// One conformance case, as `conformance/tests/*.json` writes it. `name`, `operation` and
/// `assertions` are required, as the schema says: a case whose `assertions` key is
/// misspelled would otherwise load with none and pass on the implicit checks alone. Keys
/// the runner does not read are ignored.
#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct TestCase {
    pub name: String,
    pub operation: String,
    #[serde(default)]
    pub method: String,
    #[serde(default)]
    pub path: String,
    #[serde(default)]
    pub path_params: Params,
    #[serde(default)]
    pub query_params: Params,
    #[serde(default)]
    pub request_body: Option<Value>,
    #[serde(default)]
    pub config_overrides: ConfigOverrides,
    #[serde(default)]
    pub mock_responses: Vec<MockResponse>,
    pub assertions: Vec<Assertion>,
}

/// `maxPages` and `maxItems` are in the schema but no fixture sets them; the runner
/// rejects a case that does rather than quietly running it without the limit.
#[derive(Debug, Default, Deserialize)]
#[serde(default, rename_all = "camelCase")]
pub struct ConfigOverrides {
    pub base_url: Option<String>,
    pub max_pages: Option<u64>,
    pub max_items: Option<u64>,
    /// The client-wide retry cap as a TOTAL attempt count. An `Option` because `0` is
    /// the value this override exists for — "no retries, exactly one attempt" — and a
    /// plain integer would make it indistinguishable from absent.
    pub max_retries: Option<u32>,
}

#[derive(Debug, Default, Clone, Deserialize)]
#[serde(default)]
pub struct MockResponse {
    pub status: u16,
    pub headers: BTreeMap<String, String>,
    pub body: Option<Value>,
    pub delay: u64,
}

#[derive(Debug, Default, Deserialize)]
#[serde(default)]
pub struct Assertion {
    #[serde(rename = "type")]
    pub kind: String,
    pub expected: Value,
    pub path: String,
    pub min: i64,
}

impl TestCase {
    pub fn has_assertion(&self, kind: &str) -> bool {
        self.assertions
            .iter()
            .any(|assertion| assertion.kind == kind)
    }

    /// The origin the fixture's Link headers are written against: the configured base
    /// URL, or the SDK's default when the case sets none.
    pub fn link_origin(&self) -> &str {
        self.config_overrides
            .base_url
            .as_deref()
            .unwrap_or("https://fizzy.do")
    }

    /// A base URL override with no responses to serve asks what the client does with an
    /// endpoint it should refuse; the case never reaches a server.
    pub fn expects_client_construction_failure(&self) -> bool {
        self.config_overrides.base_url.is_some() && self.mock_responses.is_empty()
    }

    /// The account the case is scoped to, as it appears in the path.
    pub fn account_id(&self) -> Option<String> {
        self.path_params.get("accountId").map(param_string)
    }

    /// The request path with `{param}` placeholders filled in and the query appended.
    /// Array-valued query params repeat the key, as the API reads them.
    pub fn request_path(&self) -> Result<String, String> {
        let mut path = expand_path(&self.path, &self.path_params)?;
        let query = query_string(&self.query_params);
        if !query.is_empty() {
            path.push('?');
            path.push_str(&query);
        }
        Ok(path)
    }

    /// Whether the case exercises pagination: several responses with a `Link` header to
    /// follow, or an assertion about where that header points.
    pub fn follows_links(&self) -> bool {
        let linked = self.mock_responses.len() > 1
            && self.mock_responses.iter().any(|mock| {
                mock.headers
                    .keys()
                    .any(|key| key.eq_ignore_ascii_case("link"))
            });
        linked || self.has_assertion("urlOrigin")
    }
}

/// A path or query parameter as the wire sees it: numbers keep every digit, so the
/// integer-precision cases round-trip a card number JavaScript could not.
pub fn param_string(value: &Value) -> String {
    match value {
        Value::String(text) => text.clone(),
        Value::Null => String::new(),
        other => other.to_string(),
    }
}

/// The characters a path segment must escape: everything the URL grammar reserves or
/// cannot carry raw, so a parameter value travels as one segment whatever it contains.
const SEGMENT: &AsciiSet = &CONTROLS
    .add(b' ')
    .add(b'"')
    .add(b'#')
    .add(b'%')
    .add(b'/')
    .add(b'<')
    .add(b'>')
    .add(b'?')
    .add(b'[')
    .add(b']')
    .add(b'`')
    .add(b'{')
    .add(b'|')
    .add(b'}');

/// Fills every `{param}` in the template from the case's parameters, percent-encoding each
/// value as one path segment. A placeholder the case does not name is an error: a typo in
/// `pathParams` must not reach the permissive mock server as a literal.
pub fn expand_path(template: &str, params: &Params) -> Result<String, String> {
    let path = params
        .iter()
        .fold(template.to_string(), |path, (key, value)| {
            let encoded = utf8_percent_encode(&param_string(value), SEGMENT).to_string();
            path.replace(&format!("{{{key}}}"), &encoded)
        });
    if let Some(start) = path.find('{') {
        let end = path[start..]
            .find('}')
            .map_or(path.len(), |end| start + end + 1);
        return Err(format!(
            "path placeholder {} has no value in pathParams",
            &path[start..end]
        ));
    }
    Ok(path)
}

pub fn query_string(params: &Params) -> String {
    let mut query = url::form_urlencoded::Serializer::new(String::new());
    for (key, value) in params {
        match value {
            Value::Array(items) => {
                for item in items {
                    query.append_pair(key, &param_string(item));
                }
            }
            other => {
                query.append_pair(key, &param_string(other));
            }
        }
    }
    query.finish()
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn params(value: &Value) -> Params {
        value.as_object().cloned().unwrap_or_default()
    }

    #[test]
    fn expands_every_placeholder_and_keeps_integer_digits() {
        let path = expand_path(
            "/{accountId}/cards/{cardNumber}",
            &params(&json!({"accountId": "999", "cardNumber": 9_007_199_254_740_993_i64})),
        );
        assert_eq!(path.as_deref(), Ok("/999/cards/9007199254740993"));
    }

    #[test]
    fn encodes_parameter_values_as_one_segment_and_rejects_missing_ones() {
        let path = expand_path(
            "/{accountId}/boards/{boardId}",
            &params(&json!({"accountId": "999", "boardId": "a/b c"})),
        );
        assert_eq!(path.as_deref(), Ok("/999/boards/a%2Fb%20c"));
        let missing = expand_path(
            "/{accountId}/boards/{boardId}",
            &params(&json!({"accountID": "999"})),
        );
        assert!(missing.unwrap_err().contains("{accountId}"));
    }

    #[test]
    fn repeats_array_query_params() {
        let query = query_string(&params(&json!({"column_ids[]": ["c1", "c2"], "q": "x y"})));
        assert_eq!(query, "column_ids%5B%5D=c1&column_ids%5B%5D=c2&q=x+y");
    }

    #[test]
    fn follows_links_only_with_several_linked_responses_or_an_origin_assertion() {
        let mut case: TestCase = serde_json::from_value(json!({
            "name": "x",
            "operation": "ListBoards",
            "assertions": [],
            "mockResponses": [{"status": 200, "headers": {"Link": "<a>; rel=\"next\""}}]
        }))
        .unwrap();
        assert!(!case.follows_links());
        case.mock_responses.push(MockResponse::default());
        assert!(case.follows_links());
        let case: TestCase = serde_json::from_value(json!({
            "name": "y",
            "operation": "ListBoards",
            "assertions": [{"type": "urlOrigin", "expected": "rejected"}]
        }))
        .unwrap();
        assert!(case.follows_links());
    }

    #[test]
    fn a_case_without_assertions_does_not_load() {
        let missing: Result<TestCase, _> = serde_json::from_value(json!({
            "name": "x",
            "operation": "ListBoards",
            "assertionss": [{"type": "noError"}]
        }));
        assert!(missing.is_err());
    }

    #[test]
    fn max_retries_zero_survives_as_zero() {
        let case: TestCase = serde_json::from_value(json!({
            "name": "a",
            "operation": "GetBoard",
            "configOverrides": {"maxRetries": 0},
            "assertions": []
        }))
        .unwrap();
        assert_eq!(case.config_overrides.max_retries, Some(0));
        let absent: TestCase = serde_json::from_value(json!({
            "name": "a",
            "operation": "GetBoard",
            "assertions": []
        }))
        .unwrap();
        assert_eq!(absent.config_overrides.max_retries, None);
    }
}
