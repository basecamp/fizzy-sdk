use std::io;
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use axum::Router;
use axum::body::{Body, Bytes};
use axum::extract::{Request, State};
use axum::http::header::CONTENT_TYPE;
use axum::http::{HeaderMap, Response, StatusCode};
use axum::response::IntoResponse;
use serde_json::Value;
use tokio::net::TcpListener;
use tokio::task::JoinHandle;
use url::Url;

use crate::assertions::next_link;
use crate::fixtures::MockResponse;

/// One request the mock server saw.
#[derive(Debug, Clone)]
pub struct RequestRecord {
    pub time: Instant,
    pub method: String,
    pub path: String,
    pub query: Vec<(String, String)>,
    pub body: Bytes,
    pub headers: HeaderMap,
}

/// A loopback server that answers each request with the case's next mock response, in
/// order, and records what it was asked. A request that follows a `Link` must ask for
/// exactly the page the link named; past the last response it answers as the Go runner
/// does: an empty page when the case was paginating, a 500 otherwise.
pub struct MockServer {
    base_url: String,
    records: Arc<Mutex<Vec<RequestRecord>>>,
    server: JoinHandle<()>,
}

struct Mocks {
    base_url: String,
    responses: Vec<MockResponse>,
    paginated: bool,
    records: Arc<Mutex<Vec<RequestRecord>>>,
}

impl MockServer {
    /// Starts the server. `link_origin` is the origin the fixture's `Link` headers are
    /// written against; a link on exactly that origin is rewritten to the server's so a
    /// same-origin next page resolves here, and a link on any other origin is served
    /// untouched.
    pub async fn start(
        responses: &[MockResponse],
        link_origin: &str,
    ) -> Result<MockServer, io::Error> {
        let listener = TcpListener::bind("127.0.0.1:0").await?;
        let base_url = format!("http://{}", listener.local_addr()?);
        let paginated = responses.iter().any(|mock| header(mock, "link").is_some());
        let responses = responses
            .iter()
            .map(|mock| rewrite_link(mock, link_origin, &base_url))
            .collect();
        let records = Arc::new(Mutex::new(Vec::new()));
        let mocks = Arc::new(Mocks {
            base_url: base_url.clone(),
            responses,
            paginated,
            records: records.clone(),
        });
        let router = Router::new().fallback(answer).with_state(mocks);
        let server = tokio::spawn(async move {
            let _ = axum::serve(listener, router).await;
        });
        Ok(MockServer {
            base_url,
            records,
            server,
        })
    }

    pub fn base_url(&self) -> &str {
        &self.base_url
    }

    pub fn shutdown(self) -> Vec<RequestRecord> {
        self.server.abort();
        self.records
            .lock()
            .map(|records| records.clone())
            .unwrap_or_default()
    }
}

/// Rewrites a `Link` header's targets whose origin is exactly the fixture origin to the
/// server's origin, and leaves every other target — relative, foreign, or merely
/// sharing a prefix with the fixture origin — as written.
fn rewrite_link(mock: &MockResponse, link_origin: &str, server_url: &str) -> MockResponse {
    let Some((name, value)) = mock
        .headers
        .iter()
        .find(|(name, _)| name.eq_ignore_ascii_case("link"))
        .map(|(name, value)| (name.clone(), value.clone()))
    else {
        return mock.clone();
    };
    let (Ok(from), Ok(to)) = (Url::parse(link_origin), Url::parse(server_url)) else {
        return mock.clone();
    };
    let rewritten_value = value
        .split(',')
        .map(|part| rewrite_target(part, &from, &to))
        .collect::<Vec<_>>()
        .join(",");
    let mut rewritten = mock.clone();
    rewritten.headers.insert(name, rewritten_value);
    rewritten
}

fn rewrite_target(part: &str, from: &Url, to: &Url) -> String {
    let Some((prefix, rest)) = part.split_once('<') else {
        return part.to_string();
    };
    let Some((target, suffix)) = rest.split_once('>') else {
        return part.to_string();
    };
    let Ok(mut url) = Url::parse(target) else {
        return part.to_string();
    };
    if url.origin() != from.origin() {
        return part.to_string();
    }
    let _ = url.set_scheme(to.scheme());
    let _ = url.set_host(to.host_str());
    let _ = url.set_port(to.port());
    format!("{prefix}<{url}>{suffix}")
}

fn header<'a>(mock: &'a MockResponse, name: &str) -> Option<&'a str> {
    mock.headers
        .iter()
        .find(|(header, _)| header.eq_ignore_ascii_case(name))
        .map(|(_, value)| value.as_str())
}

/// The page the previous response's `Link` told the client to ask for next, as a
/// path-and-query on this server. `None` when the previous response had no next link or
/// pointed away from this server, which is the client's problem to refuse, not ours.
fn expected_page(mocks: &Mocks, index: usize) -> Option<String> {
    let previous = mocks.responses.get(index.checked_sub(1)?)?;
    let target = next_link(header(previous, "link")?)?;
    let base = Url::parse(&mocks.base_url).ok()?;
    let next = base.join(&target).ok()?;
    (next.origin() == base.origin()).then(|| match next.query() {
        Some(query) => format!("{}?{query}", next.path()),
        None => next.path().to_string(),
    })
}

async fn answer(State(mocks): State<Arc<Mocks>>, request: Request) -> Response<Body> {
    let (parts, body) = request.into_parts();
    let bytes = axum::body::to_bytes(body, usize::MAX)
        .await
        .unwrap_or_default();
    let requested = match parts.uri.query() {
        Some(query) => format!("{}?{query}", parts.uri.path()),
        None => parts.uri.path().to_string(),
    };
    let index = {
        let Ok(mut records) = mocks.records.lock() else {
            return (StatusCode::INTERNAL_SERVER_ERROR, "record lock poisoned").into_response();
        };
        records.push(RequestRecord {
            time: Instant::now(),
            method: parts.method.to_string(),
            path: parts.uri.path().to_string(),
            query: url::form_urlencoded::parse(parts.uri.query().unwrap_or_default().as_bytes())
                .map(|(name, value)| (name.into_owned(), value.into_owned()))
                .collect(),
            body: bytes,
            headers: parts.headers.clone(),
        });
        records.len() - 1
    };

    if let Some(expected) = expected_page(&mocks, index).filter(|expected| *expected != requested) {
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("expected the next page {expected}, got a request for {requested}"),
        )
            .into_response();
    }

    match mocks.responses.get(index) {
        Some(mock) => {
            if mock.delay > 0 {
                tokio::time::sleep(Duration::from_millis(mock.delay)).await;
            }
            serve(mock)
        }
        None if mocks.paginated => {
            (StatusCode::OK, [(CONTENT_TYPE, "application/json")], "[]").into_response()
        }
        None => StatusCode::INTERNAL_SERVER_ERROR.into_response(),
    }
}

fn serve(mock: &MockResponse) -> Response<Body> {
    let mut response = Response::builder().status(mock.status);
    for (name, value) in &mock.headers {
        response = response.header(name, value);
    }
    let body = match &mock.body {
        Some(Value::Null) | None => Body::empty(),
        Some(body) => Body::from(serde_json::to_vec(body).unwrap_or_default()),
    };
    response
        .body(body)
        .unwrap_or_else(|_| StatusCode::INTERNAL_SERVER_ERROR.into_response())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn linked(link: &str) -> MockResponse {
        let mut mock = MockResponse::default();
        mock.headers.insert("Link".into(), link.into());
        mock
    }

    #[test]
    fn rewrites_the_fixture_origin_to_the_server() {
        let mock = linked("<http://localhost:3000/999/boards.json?page=2>; rel=\"next\"");
        let rewritten = rewrite_link(&mock, "http://localhost:3000", "http://127.0.0.1:4321");
        assert_eq!(
            rewritten.headers["Link"],
            "<http://127.0.0.1:4321/999/boards.json?page=2>; rel=\"next\""
        );
    }

    #[test]
    fn leaves_foreign_relative_and_prefix_sharing_links_alone() {
        for link in [
            "<https://evil.example.com/999/boards.json?page=2>; rel=\"next\"",
            "</999/boards.json?page=2>; rel=\"next\"",
            "<http://fizzy.do/999/boards.json?page=2>; rel=\"next\"",
            "<https://fizzy.do:444/999/boards.json?page=2>; rel=\"next\"",
            "<https://fizzy.do.evil.example/999/boards.json?next=https://fizzy.do/x>; rel=\"next\"",
        ] {
            let mock = linked(link);
            let rewritten = rewrite_link(&mock, "https://fizzy.do", "http://127.0.0.1:4321");
            assert_eq!(rewritten.headers["Link"], link);
        }
    }

    #[test]
    fn rewrites_only_the_matching_target_in_a_multi_link_header() {
        let mock = linked(
            "<https://fizzy.do/999/boards.json?page=2>; rel=\"next\", <https://other.example/x>; rel=\"prev\"",
        );
        let rewritten = rewrite_link(&mock, "https://fizzy.do", "http://127.0.0.1:4321");
        assert_eq!(
            rewritten.headers["Link"],
            "<http://127.0.0.1:4321/999/boards.json?page=2>; rel=\"next\", <https://other.example/x>; rel=\"prev\""
        );
    }

    #[test]
    fn expects_the_page_the_previous_link_named() {
        let mocks = Mocks {
            base_url: "http://127.0.0.1:4321".into(),
            responses: vec![
                linked("</999/boards.json?page=2>; rel=\"next\""),
                MockResponse::default(),
                linked("<https://evil.example.com/x>; rel=\"next\""),
                MockResponse::default(),
            ],
            paginated: true,
            records: Arc::new(Mutex::new(Vec::new())),
        };
        assert_eq!(expected_page(&mocks, 0), None);
        assert_eq!(
            expected_page(&mocks, 1).as_deref(),
            Some("/999/boards.json?page=2")
        );
        assert_eq!(expected_page(&mocks, 2), None);
        assert_eq!(expected_page(&mocks, 3), None);
    }
}
