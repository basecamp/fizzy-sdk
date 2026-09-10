//! Everything that touches the SDK: building the client, dispatching a case through the
//! raw verbs, and reading errors back. The rest of the runner sees `Outcome` and the
//! accessor functions here, so an SDK API change lands in one file.

use std::sync::{Arc, Mutex};
use std::time::Duration;

use fizzy_sdk::http::Method;
use fizzy_sdk::routes::{Pagination, Route};
use fizzy_sdk::{
    Client, ClientBuilder, Config, Error, RequestOptions, Response, StaticTokenProvider, routes,
};
use serde_json::Value;

use crate::fixtures::TestCase;
use crate::transport::Intercept;

pub type SdkError = Error;

const TOKEN: &str = "test-token";

/// What the SDK answered, in a shape the assertions can read.
pub enum Outcome {
    /// One response, from a raw verb.
    Response {
        status: u16,
        headers: axum::http::HeaderMap,
        body: Value,
    },
    /// Every item across every page, from `get_all`, as one JSON array.
    Items(Value),
    /// A client built without a request, for the construction-failure cases.
    Client,
}

impl Outcome {
    pub fn body(&self) -> Option<&Value> {
        match self {
            Outcome::Response { body, .. } | Outcome::Items(body) => Some(body),
            Outcome::Client => None,
        }
    }
}

pub fn code_of(error: &Error) -> String {
    error.code().as_str().to_string()
}

pub fn status_of(error: &Error) -> Option<u16> {
    error.http_status()
}

pub fn request_id_of(error: &Error) -> Option<String> {
    error.request_id().map(str::to_string)
}

/// The route the case names. An operation the SDK does not know is a failure: a fixture
/// can only test what the model describes.
fn route(case: &TestCase) -> Result<&'static Route, String> {
    routes::ROUTES
        .iter()
        .find(|route| route.id == case.operation)
        .copied()
        .ok_or_else(|| format!("unknown operation {:?}", case.operation))
}

/// A case must agree with the generated route it names: same method, same path template
/// (Fizzy serves each route with or without `.json`, so that suffix is the one allowance).
/// The request still goes out as the fixture spells it, through the raw verbs; this is
/// what stops a fixture from testing a request the model does not describe.
pub fn validate(case: &TestCase) -> Result<(), String> {
    let route = route(case)?;
    if case.config_overrides.max_pages.is_some() || case.config_overrides.max_items.is_some() {
        return Err("configOverrides.maxPages/maxItems are not supported by this runner".into());
    }
    let method = method(case)?;
    if method != route.method {
        return Err(format!(
            "fixture sends {method} but the generated route {} is {}",
            route.id, route.method
        ));
    }
    if !case.path.is_empty() && without_json(&case.path) != without_json(route.path) {
        return Err(format!(
            "fixture path {} does not match the generated route {} path {}",
            case.path, route.id, route.path
        ));
    }
    Ok(())
}

fn without_json(path: &str) -> &str {
    path.strip_suffix(".json").unwrap_or(path)
}

fn method(case: &TestCase) -> Result<Method, String> {
    match case.method.as_str() {
        "" | "GET" => Ok(Method::GET),
        "POST" => Ok(Method::POST),
        "PUT" => Ok(Method::PUT),
        "PATCH" => Ok(Method::PATCH),
        "DELETE" => Ok(Method::DELETE),
        other => Err(format!("unsupported method {other:?}")),
    }
}

/// The client and the count of requests its transport refused to send off the mock server.
fn build_client(
    case: &TestCase,
    base_url: &str,
    reachable: Option<&str>,
) -> Result<(Client, Arc<Mutex<usize>>), Error> {
    let (transport, foreign) = Intercept::new(reachable)?;
    let mut builder = ClientBuilder::new(Config::default().with_base_url(base_url))
        .token_provider(StaticTokenProvider::new(TOKEN))
        .http_client(transport);
    if let Some(max_retries) = case.config_overrides.max_retries {
        builder = builder.max_attempts(max_retries);
    }
    // Fast retries unless the case measures the delay itself.
    if !case.has_assertion("delayBetweenRequests") {
        builder = builder
            .base_delay(Duration::from_millis(1))
            .max_jitter(Duration::from_millis(1));
    }
    builder.build().map(|client| (client, foreign))
}

/// Builds the client the case configures and reports whether that succeeded, for the
/// cases that never reach a server.
pub fn construct_client(case: &TestCase) -> Result<Outcome, Error> {
    build_client(case, case.link_origin(), None).map(|_| Outcome::Client)
}

/// Runs the case against the mock server through the raw verbs, the way the Go,
/// TypeScript and Ruby runners do: the account-scoped client for a path under an
/// account, the bare client otherwise.
/// The outcome, and how many requests the transport refused to send off the mock server —
/// counted whether the operation then succeeded or failed, since a refused request is
/// usually why it failed.
pub async fn execute(case: &TestCase, base_url: &str) -> (Result<Outcome, Error>, usize) {
    let (client, foreign) = match build_client(case, base_url, Some(base_url)) {
        Ok(built) => built,
        Err(error) => return (Err(error), 0),
    };
    let outcome = dispatch(&client, case).await;
    let refused = foreign.lock().map(|count| *count).unwrap_or_default();
    (outcome, refused)
}

async fn dispatch(client: &Client, case: &TestCase) -> Result<Outcome, Error> {
    let route = route(case).map_err(Error::usage)?;
    let method = method(case).map_err(Error::usage)?;
    let full_path = case.request_path().map_err(Error::usage)?;

    // The behavior model's contract exceptions, as the Go runner applies them: a
    // non-POST with no retry policy opts out, an idempotent POST opts in.
    let mut options = RequestOptions::new();
    if route.retry.is_none() && method != Method::POST {
        options = options.no_retry();
    }
    if route.idempotent && method == Method::POST {
        options = options.idempotent();
    }

    // Paginated by the route table's say-so, not by the operation's name: SearchCards
    // walks Link headers too.
    let paginate = !matches!(route.pagination, Pagination::None) && case.follows_links();
    let body = case.request_body.as_ref();
    let Some(account) = case.account_id() else {
        if paginate {
            return client
                .get_all(&full_path)
                .await
                .map(|items| Outcome::Items(Value::Array(items)));
        }
        let response = match (method, body) {
            (Method::GET, _) => client.get_with(&full_path, &options).await?,
            (Method::DELETE, _) => client.delete_with(&full_path, &options).await?,
            (Method::POST, Some(body)) => client.post_with(&full_path, body, &options).await?,
            (Method::PUT, Some(body)) => client.put_with(&full_path, body, &options).await?,
            (Method::PATCH, Some(body)) => client.patch_with(&full_path, body, &options).await?,
            (method, None) => bodiless(client, method, &full_path, &options).await?,
            (method, _) => return Err(Error::usage(format!("unsupported method {method}"))),
        };
        return Ok(outcome(&response));
    };

    let path = full_path
        .strip_prefix(&format!("/{account}"))
        .map_or(full_path.clone(), str::to_string);
    let scoped = client.for_account(account)?;
    if paginate {
        return scoped
            .get_all(&path)
            .await
            .map(|items| Outcome::Items(Value::Array(items)));
    }
    let response = match (method, body) {
        (Method::GET, _) => scoped.get_with(&path, &options).await?,
        (Method::DELETE, _) => scoped.delete_with(&path, &options).await?,
        (Method::POST, Some(body)) => scoped.post_with(&path, body, &options).await?,
        (Method::PUT, Some(body)) => scoped.put_with(&path, body, &options).await?,
        (Method::PATCH, Some(body)) => scoped.patch_with(&path, body, &options).await?,
        (method, None) => bodiless(scoped.client(), method, &full_path, &options).await?,
        (method, _) => return Err(Error::usage(format!("unsupported method {method}"))),
    };
    Ok(outcome(&response))
}

/// A write with no body — `CloseCard`, `MarkCardRead` — sent as the raw verbs cannot:
/// they always encode a body. `Client::request` is the same raw entry point without one,
/// so the path carries its account prefix already.
async fn bodiless(
    client: &Client,
    method: Method,
    full_path: &str,
    options: &RequestOptions,
) -> Result<Response, Error> {
    let mut operation = client.request(method, full_path);
    if options.idempotent {
        operation.idempotent(true);
    }
    if options.no_retry {
        operation.no_retry();
    }
    client.execute(operation).await
}

fn outcome(response: &Response) -> Outcome {
    let body = if response.body.is_empty() {
        Value::Null
    } else {
        serde_json::from_slice(&response.body).unwrap_or(Value::Null)
    };
    Outcome::Response {
        status: response.status.as_u16(),
        headers: response.headers.clone(),
        body,
    }
}
