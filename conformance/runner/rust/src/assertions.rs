use std::time::Duration;

use axum::http::HeaderMap;
use serde_json::Value;
use url::Url;

use crate::fixtures::{Assertion, TestCase};
use crate::operations::{Outcome, SdkError, code_of, request_id_of, status_of};
use crate::server::RequestRecord;

/// One case after it ran: what the SDK answered and what the mock server saw.
pub struct Run<'a> {
    pub case: &'a TestCase,
    pub outcome: &'a Result<Outcome, SdkError>,
    pub recorded: &'a [RequestRecord],
    pub base_url: &'a str,
}

/// Every assertion in the case, in order; the first failure is the case's failure. An
/// assertion type the runner does not know is a failure too: a case is never passed by
/// being ignored.
pub fn check_all(run: &Run) -> Result<(), String> {
    check_request_methods(run)?;
    for assertion in &run.case.assertions {
        check(run, assertion).map_err(|message| format!("[{}] {message}", assertion.kind))?;
    }
    Ok(())
}

fn check(run: &Run, assertion: &Assertion) -> Result<(), String> {
    match assertion.kind.as_str() {
        "requestCount" => check_request_count(run, assertion),
        "delayBetweenRequests" => check_delay_between_requests(run, assertion),
        "statusCode" => check_status_code(run, assertion),
        "noError" => check_no_error(run),
        "errorCode" => check_error_code(run, assertion),
        "errorField" => check_error_field(run, assertion),
        "headerPresent" => check_header_present(run, assertion),
        "headerValue" => check_header_value(run, assertion),
        "requestPath" => check_request_path(run, assertion),
        "urlOrigin" => check_url_origin(run, assertion),
        "responseMeta" => check_response_meta(run, assertion),
        "responseBody" => check_response_body(run, assertion),
        "errorMessage" => check_error_message(run, assertion),
        "headerInjected" => check_header_injected(run, assertion),
        "requestScheme" => check_request_scheme(run, assertion),
        "requestBodyField" => check_request_body_field(run, assertion),
        "requestQueryParam" => check_request_query_param(run, assertion),
        kind => Err(format!("unknown assertion type {kind:?}")),
    }
}

/// Every request the server saw — the first, a retry, a next page — must use the method
/// the case names; a paginated case follows its links with GET.
fn check_request_methods(run: &Run) -> Result<(), String> {
    let expected = if run.case.method.is_empty() {
        "GET"
    } else {
        run.case.method.as_str()
    };
    match run.recorded.iter().find(|record| record.method != expected) {
        Some(record) => Err(format!(
            "[requestMethod] expected every request to be {expected}, got {} for {}",
            record.method, record.path
        )),
        None => Ok(()),
    }
}

fn check_request_count(run: &Run, assertion: &Assertion) -> Result<(), String> {
    let expected = expected_int(assertion)?;
    let actual = i64::try_from(run.recorded.len()).unwrap_or(i64::MAX);
    if actual == expected {
        Ok(())
    } else {
        Err(format!("expected {expected} requests, got {actual}"))
    }
}

/// Every interval between consecutive requests, not only the first: a retry loop that
/// backs off once and then hammers would pass a first-interval check.
fn check_delay_between_requests(run: &Run, assertion: &Assertion) -> Result<(), String> {
    let minimum = if assertion.min > 0 {
        assertion.min
    } else {
        expected_int(assertion)?
    };
    let minimum = Duration::from_millis(u64::try_from(minimum).unwrap_or_default());
    if run.recorded.len() < 2 {
        return Err(format!(
            "need at least 2 requests to measure a delay, got {}",
            run.recorded.len()
        ));
    }
    for (index, pair) in run.recorded.windows(2).enumerate() {
        let delay = pair[1].time.duration_since(pair[0].time);
        if delay < minimum {
            return Err(format!(
                "delay between request {} and {} was {delay:?}, expected >= {minimum:?}",
                index + 1,
                index + 2
            ));
        }
    }
    Ok(())
}

/// The status the case is about. A failure carries it on the error itself; only a success
/// has no error to read it from, and there the response's status is the answer.
fn check_status_code(run: &Run, assertion: &Assertion) -> Result<(), String> {
    let expected = expected_int(assertion)?;
    let actual = match run.outcome {
        Ok(Outcome::Response { status, .. }) => i64::from(*status),
        Ok(Outcome::Items(_)) => {
            return Err(format!(
                "expected status {expected}, but a paginated fetch has no single response"
            ));
        }
        Ok(Outcome::Client) => {
            return Err(format!(
                "expected status {expected}, but no request was made"
            ));
        }
        Err(error) => match status_of(error).or_else(|| inferred_status(&code_of(error))) {
            Some(status) => i64::from(status),
            None => {
                return Err(format!(
                    "expected status {expected}, but the SDK error carries no HTTP status: {error}"
                ));
            }
        },
    };
    if actual == expected {
        Ok(())
    } else {
        Err(format!("expected status {expected}, got {actual}"))
    }
}

/// The status an error code implies, for an error the SDK raised without one.
fn inferred_status(code: &str) -> Option<u16> {
    match code {
        "auth_required" => Some(401),
        "forbidden" => Some(403),
        "not_found" => Some(404),
        "validation" => Some(422),
        "rate_limit" => Some(429),
        _ => None,
    }
}

fn check_no_error(run: &Run) -> Result<(), String> {
    match run.outcome {
        Ok(_) => Ok(()),
        Err(error) => Err(format!("expected no error, got: {error}")),
    }
}

fn check_error_code(run: &Run, assertion: &Assertion) -> Result<(), String> {
    let expected = expected_string(assertion)?;
    match run.outcome {
        Ok(_) => Err(format!("expected error code {expected:?}, got no error")),
        Err(error) if code_of(error) == expected => Ok(()),
        Err(error) => Err(format!(
            "expected error code {expected:?}, got {:?}",
            code_of(error)
        )),
    }
}

fn check_error_field(run: &Run, assertion: &Assertion) -> Result<(), String> {
    let Err(error) = run.outcome else {
        return Err(format!(
            "expected an error to read {:?} from, got no error",
            assertion.path
        ));
    };
    match assertion.path.as_str() {
        "requestId" => {
            let expected = expected_string(assertion)?;
            let actual = request_id_of(error).unwrap_or_default();
            if actual == expected {
                Ok(())
            } else {
                Err(format!("expected requestId {expected:?}, got {actual:?}"))
            }
        }
        "httpStatus" => {
            let expected = expected_int(assertion)?;
            let actual = status_of(error).map(i64::from).unwrap_or_default();
            if actual == expected {
                Ok(())
            } else {
                Err(format!("expected httpStatus {expected}, got {actual}"))
            }
        }
        field => Err(format!("unknown error field {field:?}")),
    }
}

fn check_header_present(run: &Run, assertion: &Assertion) -> Result<(), String> {
    let record = last_request(run)?;
    if header(&record.headers, &assertion.path).is_empty() {
        Err(format!("header {:?} not present", assertion.path))
    } else {
        Ok(())
    }
}

fn check_header_value(run: &Run, assertion: &Assertion) -> Result<(), String> {
    let expected = expected_string(assertion)?;
    let record = last_request(run)?;
    let actual = header(&record.headers, &assertion.path);
    if actual == expected {
        Ok(())
    } else {
        Err(format!(
            "header {:?} expected {expected:?}, got mismatch (len={})",
            assertion.path,
            actual.len()
        ))
    }
}

/// The first request's path, matched exactly. Fizzy serves some routes with `.json` and
/// some without, and the fixtures spell each one the way the API takes it.
fn check_request_path(run: &Run, assertion: &Assertion) -> Result<(), String> {
    let expected = expected_string(assertion)?;
    let record = first_request(run)?;
    if record.path == expected {
        Ok(())
    } else {
        Err(format!("expected {expected:?}, got {:?}", record.path))
    }
}

/// A cross-origin `Link` must be refused as a usage error before any request goes out
/// to it; the mock server serving a foreign link is the fixture's sanity check.
fn check_url_origin(run: &Run, assertion: &Assertion) -> Result<(), String> {
    let expected = expected_string(assertion)?;
    if expected != "rejected" {
        return Err(format!(
            "unsupported expected value {expected:?} (only \"rejected\" is supported)"
        ));
    }
    let link = run
        .case
        .mock_responses
        .iter()
        .rev()
        .find_map(|mock| {
            mock.headers
                .iter()
                .find(|(name, _)| name.eq_ignore_ascii_case("link"))
                .map(|(_, value)| value.clone())
        })
        .ok_or_else(|| "no Link header in the mock responses to reject".to_string())?;
    let target = next_link(&link).ok_or_else(|| format!("no next URL in Link header {link:?}"))?;
    let server = Url::parse(run.base_url).map_err(|error| format!("bad server URL: {error}"))?;
    if Url::parse(&target).is_ok_and(|next| same_origin(&next, &server)) {
        return Err(format!(
            "fixture Link {target} has the server's origin; nothing to reject"
        ));
    }
    let pages = run.case.mock_responses.len();
    if run.recorded.len() != pages {
        return Err(format!(
            "expected the {pages} mocked page(s) to be fetched before the Link was refused, got {} requests",
            run.recorded.len()
        ));
    }
    match run.outcome {
        Err(error) if code_of(error) == "usage" => Ok(()),
        Err(error) => Err(format!(
            "expected the cross-origin Link to be refused as a usage error, got {:?}: {error}",
            code_of(error)
        )),
        Ok(_) => Err("expected the cross-origin Link to be rejected, got success".to_string()),
    }
}

fn check_response_meta(run: &Run, assertion: &Assertion) -> Result<(), String> {
    let Ok(Outcome::Response { headers, .. }) = run.outcome else {
        return Err(format!(
            "expected a response to read responseMeta.{} from",
            assertion.path
        ));
    };
    match assertion.path.as_str() {
        "nextPage" => {
            let expected = expected_string(assertion)?;
            let actual = header(headers, "link");
            match next_link(actual) {
                Some(next) if next == expected => Ok(()),
                Some(next) => Err(format!("expected next page {expected:?}, got {next:?}")),
                None => Err("Link header has no next URL".to_string()),
            }
        }
        "totalCount" => {
            let expected = expected_int(assertion)?;
            match header(headers, "x-total-count").parse::<i64>() {
                Ok(actual) if actual == expected => Ok(()),
                Ok(actual) => Err(format!("expected X-Total-Count {expected}, got {actual}")),
                Err(_) => Err("X-Total-Count header not present".to_string()),
            }
        }
        path => Err(format!("unknown responseMeta path {path:?}")),
    }
}

fn check_response_body(run: &Run, assertion: &Assertion) -> Result<(), String> {
    let body = match run.outcome {
        Err(error) => return Err(format!("expected a response body, got: {error}")),
        Ok(outcome) => outcome
            .body()
            .ok_or_else(|| "no response body captured".to_string())?,
    };
    let actual = lookup(body, &assertion.path)
        .ok_or_else(|| format!("field {:?} not present in the response", assertion.path))?;
    if values_match(&assertion.expected, actual) {
        Ok(())
    } else {
        Err(format!(
            "expected {}.{} = {}, got {}",
            "body",
            assertion.path,
            display(&assertion.expected),
            display(actual)
        ))
    }
}

fn check_error_message(run: &Run, assertion: &Assertion) -> Result<(), String> {
    let expected = expected_string(assertion)?;
    match run.outcome {
        Ok(_) => Err(format!(
            "expected an error containing {expected:?}, got no error"
        )),
        Err(error) if error.to_string().contains(expected) => Ok(()),
        Err(error) => Err(format!(
            "expected message containing {expected:?}, got {:?}",
            error.to_string()
        )),
    }
}

/// A header the SDK adds on its own: present on the first request, and equal to the
/// expected value when the assertion names one.
fn check_header_injected(run: &Run, assertion: &Assertion) -> Result<(), String> {
    let record = first_request(run)?;
    let actual = header(&record.headers, &assertion.path);
    match assertion.expected.as_str() {
        _ if actual.is_empty() => Err(format!("header {:?} not injected", assertion.path)),
        Some(expected) if actual != expected => Err(format!(
            "header {:?} expected {expected:?}, got {actual:?}",
            assertion.path
        )),
        _ => Ok(()),
    }
}

fn check_request_scheme(run: &Run, assertion: &Assertion) -> Result<(), String> {
    let expected = expected_string(assertion)?;
    first_request(run)?;
    let actual = Url::parse(run.base_url)
        .map(|url| url.scheme().to_string())
        .map_err(|error| format!("bad server URL: {error}"))?;
    if actual == expected {
        Ok(())
    } else {
        Err(format!("expected scheme {expected:?}, got {actual:?}"))
    }
}

fn check_request_body_field(run: &Run, assertion: &Assertion) -> Result<(), String> {
    let expected = expected_string(assertion)?;
    let record = last_request(run)?;
    let body: Value = serde_json::from_slice(&record.body)
        .map_err(|error| format!("could not parse the request body: {error}"))?;
    let Some(fields) = body.as_object() else {
        return Err("request body is not a JSON object".to_string());
    };
    if fields.contains_key(expected) {
        Ok(())
    } else {
        Err(format!(
            "field {expected:?} not found in request body (keys: {:?})",
            fields.keys().collect::<Vec<_>>()
        ))
    }
}

/// The first request's query, so a retry cannot stand in for the request under test.
/// An array expectation wants every repeated value, in order.
fn check_request_query_param(run: &Run, assertion: &Assertion) -> Result<(), String> {
    let record = first_request(run)?;
    let actual: Vec<&str> = record
        .query
        .iter()
        .filter(|(name, _)| *name == assertion.path)
        .map(|(_, value)| value.as_str())
        .collect();
    if let Some(items) = assertion.expected.as_array() {
        let expected: Vec<String> = items.iter().map(display).collect();
        if actual == expected {
            Ok(())
        } else {
            Err(format!(
                "param {:?} expected {expected:?}, got {actual:?}",
                assertion.path
            ))
        }
    } else {
        let expected = display(&assertion.expected);
        match actual.first() {
            Some(value) if *value == expected => Ok(()),
            Some(value) => Err(format!(
                "param {:?} expected {expected:?}, got {value:?}",
                assertion.path
            )),
            None => Err(format!(
                "param {:?} expected {expected:?}, got no value",
                assertion.path
            )),
        }
    }
}

fn first_request<'a>(run: &Run<'a>) -> Result<&'a RequestRecord, String> {
    run.recorded.first().ok_or_else(no_requests)
}

fn last_request<'a>(run: &Run<'a>) -> Result<&'a RequestRecord, String> {
    run.recorded.last().ok_or_else(no_requests)
}

fn no_requests() -> String {
    "no requests recorded".to_string()
}

fn header<'a>(headers: &'a HeaderMap, name: &str) -> &'a str {
    headers
        .get(name)
        .and_then(|value| value.to_str().ok())
        .unwrap_or_default()
}

/// The `rel="next"` target of a `Link` header, if any.
pub fn next_link(link: &str) -> Option<String> {
    link.split(',').find_map(|part| {
        let (target, params) = part.trim().split_once('>')?;
        let target = target.trim().strip_prefix('<')?;
        params
            .split(';')
            .map(|param| param.trim().replace(['"', '\''], ""))
            .any(|param| param.eq_ignore_ascii_case("rel=next"))
            .then(|| target.to_string())
    })
}

fn same_origin(a: &Url, b: &Url) -> bool {
    a.scheme().eq_ignore_ascii_case(b.scheme())
        && a.host_str()
            .unwrap_or_default()
            .eq_ignore_ascii_case(b.host_str().unwrap_or_default())
        && a.port_or_known_default() == b.port_or_known_default()
}

fn expected_int(assertion: &Assertion) -> Result<i64, String> {
    assertion
        .expected
        .as_i64()
        .ok_or_else(|| format!("expected an integer, got {}", display(&assertion.expected)))
}

fn expected_string(assertion: &Assertion) -> Result<&str, String> {
    assertion
        .expected
        .as_str()
        .ok_or_else(|| format!("expected a string, got {}", display(&assertion.expected)))
}

/// Walks a decoded JSON value by a dot-separated path, reading integer segments as array
/// indexes.
fn lookup<'a>(value: &'a Value, path: &str) -> Option<&'a Value> {
    path.split('.')
        .try_fold(value, |current, segment| match current {
            Value::Object(fields) => fields.get(segment),
            Value::Array(items) => items.get(segment.parse::<usize>().ok()?),
            _ => None,
        })
}

fn values_match(expected: &Value, actual: &Value) -> bool {
    if let (Some(expected), Some(actual)) = (expected.as_i64(), actual.as_i64()) {
        expected == actual
    } else if let (Some(expected), Some(actual)) = (expected.as_f64(), actual.as_f64()) {
        (expected - actual).abs() < f64::EPSILON
    } else if let (Some(expected), Some(actual)) = (expected.as_bool(), actual.as_bool()) {
        expected == actual
    } else {
        display(expected) == display(actual)
    }
}

fn display(value: &Value) -> String {
    match value {
        Value::String(text) => text.clone(),
        other => other.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn next_link_reads_the_next_relation_only() {
        let link = "<https://fizzy.do/999/boards.json?page=1>; rel=\"prev\", </999/boards.json?page=2>; rel=\"next\"";
        assert_eq!(next_link(link).as_deref(), Some("/999/boards.json?page=2"));
        assert_eq!(next_link("<https://x/y>; rel=\"prev\""), None);
        assert_eq!(next_link(""), None);
    }

    #[test]
    fn lookup_walks_objects_and_arrays() {
        let body = json!({"boards": [{"id": "b1"}, {"id": "b2"}]});
        assert_eq!(lookup(&body, "boards.1.id"), Some(&json!("b2")));
        assert_eq!(lookup(&body, "boards.9.id"), None);
        assert_eq!(lookup(&body, "boards.x"), None);
    }

    #[test]
    fn values_match_compares_by_kind() {
        assert!(values_match(&json!(1), &json!(1)));
        assert!(values_match(&json!("1"), &json!(1)));
        assert!(!values_match(&json!(true), &json!(false)));
        assert!(!values_match(&json!("a"), &json!("b")));
    }

    #[test]
    fn same_origin_ignores_case_and_default_ports() {
        let a = Url::parse("https://Fizzy.do/x").unwrap();
        let b = Url::parse("https://fizzy.do:443/y").unwrap();
        let c = Url::parse("http://fizzy.do/y").unwrap();
        assert!(same_origin(&a, &b));
        assert!(!same_origin(&a, &c));
    }
}
