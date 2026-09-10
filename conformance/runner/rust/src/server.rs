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
    /// When the request arrived.
    pub time: Instant,
    /// When its answer was sent, after any delay the mock added; the next request's
    /// backoff is measured from here.
    pub served_at: Instant,
    pub method: String,
    pub path: String,
    pub query: Vec<(String, String)>,
    pub body: Bytes,
    pub headers: HeaderMap,
}

/// What the server saw once the case ran.
pub struct Recorded {
    pub requests: Vec<RequestRecord>,
    /// Follow-on requests that asked for a page other than the one the previous `Link`
    /// named. Always a failure, whatever the SDK made of the 500 they were answered with.
    pub wrong_pages: usize,
}

/// A loopback server that answers each request with the case's next mock response, in
/// order, and records what it was asked. A request that follows a `Link` must ask for
/// exactly the page the link named; past the last response it answers as the Go runner
/// does: an empty page when the case was paginating, a 500 otherwise.
///
/// A `Link` on any origin other than the configured one is served exactly as the fixture
/// wrote it; the runner's transport refuses to send there, so the SDK is judged on the URL
/// the fixture meant and nothing leaves the machine.
pub struct MockServer {
    base_url: String,
    records: Arc<Mutex<Vec<RequestRecord>>>,
    wrong_pages: Arc<Mutex<usize>>,
    server: JoinHandle<()>,
}

struct Mocks {
    base_url: String,
    responses: Vec<MockResponse>,
    paginated: bool,
    records: Arc<Mutex<Vec<RequestRecord>>>,
    wrong_pages: Arc<Mutex<usize>>,
}

impl MockServer {
    /// Starts the server. `link_origin` is the origin the fixture's `Link` headers are
    /// written against: an absolute link on exactly that origin is rewritten to the server
    /// so a same-origin next page resolves here; every other link — relative, foreign,
    /// another scheme, or merely sharing a prefix — is served as written.
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
        let wrong_pages = Arc::new(Mutex::new(0));
        let mocks = Arc::new(Mocks {
            base_url: base_url.clone(),
            responses,
            paginated,
            records: records.clone(),
            wrong_pages: wrong_pages.clone(),
        });
        let router = Router::new().fallback(answer).with_state(mocks);
        let server = tokio::spawn(async move {
            let _ = axum::serve(listener, router).await;
        });
        Ok(MockServer {
            base_url,
            records,
            wrong_pages,
            server,
        })
    }

    pub fn base_url(&self) -> &str {
        &self.base_url
    }

    pub fn shutdown(self) -> Recorded {
        self.server.abort();
        Recorded {
            requests: self
                .records
                .lock()
                .map(|records| records.clone())
                .unwrap_or_default(),
            wrong_pages: self
                .wrong_pages
                .lock()
                .map(|count| *count)
                .unwrap_or_default(),
        }
    }
}

/// Rewrites a `Link` header's targets whose origin is exactly the fixture origin to the
/// server's, and leaves every other target as written.
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
    let rewritten_value = rewrite_targets(&value, &from, &to);
    let mut rewritten = mock.clone();
    rewritten.headers.insert(name, rewritten_value);
    rewritten
}

/// Walks the header for `<target>` segments and rewrites each target by its own origin. A
/// URI-reference cannot contain `>`, so the brackets are the only delimiter that matters;
/// commas inside a target or a quoted parameter are left alone.
fn rewrite_targets(header: &str, from: &Url, to: &Url) -> String {
    let mut out = String::with_capacity(header.len());
    let mut rest = header;
    while let Some((before, after)) = rest.split_once('<') {
        out.push_str(before);
        out.push('<');
        let Some((target, tail)) = after.split_once('>') else {
            out.push_str(after);
            return out;
        };
        out.push_str(&rewrite_target(target, from, to));
        out.push('>');
        rest = tail;
    }
    out.push_str(rest);
    out
}

/// A network-path reference (`//host/path`) names an origin too; it is resolved against
/// the fixture origin's scheme before being classified, so it is rewritten or refused by
/// the origin it actually names rather than passed through unread.
fn rewrite_target(target: &str, from: &Url, to: &Url) -> String {
    let parsed = if target.starts_with("//") {
        from.join(target)
    } else {
        Url::parse(target)
    };
    let Ok(mut url) = parsed else {
        return target.to_string();
    };
    if url.origin() != from.origin() {
        return url.to_string();
    }
    let _ = url.set_scheme(to.scheme());
    let _ = url.set_host(to.host_str());
    let _ = url.set_port(to.port());
    url.to_string()
}

fn header<'a>(mock: &'a MockResponse, name: &str) -> Option<&'a str> {
    mock.headers
        .iter()
        .find(|(header, _)| header.eq_ignore_ascii_case(name))
        .map(|(_, value)| value.as_str())
}

/// The page the previous response's `Link` told the client to ask for next, as a
/// path-and-query on this server, resolved against the URL that response answered — a
/// relative target like `?page=2` names a page under it. `None` when the previous response
/// was not a page at all (a 429 carrying a `Link` is retried, not followed), had no next
/// link, or pointed away from this server, which is the client's problem to refuse, not
/// ours.
fn expected_page(mocks: &Mocks, index: usize, previous_request: &str) -> Option<String> {
    let previous = mocks.responses.get(index.checked_sub(1)?)?;
    if !(200..300).contains(&previous.status) {
        return None;
    }
    let target = next_link(header(previous, "link")?)?;
    let base = Url::parse(&mocks.base_url)
        .ok()?
        .join(previous_request)
        .ok()?;
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
    let (index, previous_request) = {
        let Ok(mut records) = mocks.records.lock() else {
            return (StatusCode::INTERNAL_SERVER_ERROR, "record lock poisoned").into_response();
        };
        let previous_request = records.last().map(|record| {
            let query = url::form_urlencoded::Serializer::new(String::new())
                .extend_pairs(&record.query)
                .finish();
            if query.is_empty() {
                record.path.clone()
            } else {
                format!("{}?{query}", record.path)
            }
        });
        records.push(RequestRecord {
            time: Instant::now(),
            served_at: Instant::now(),
            method: parts.method.to_string(),
            path: parts.uri.path().to_string(),
            query: url::form_urlencoded::parse(parts.uri.query().unwrap_or_default().as_bytes())
                .map(|(name, value)| (name.into_owned(), value.into_owned()))
                .collect(),
            body: bytes,
            headers: parts.headers.clone(),
        });
        (records.len() - 1, previous_request.unwrap_or_default())
    };

    if let Some(expected) =
        expected_page(&mocks, index, &previous_request).filter(|expected| *expected != requested)
    {
        if let Ok(mut count) = mocks.wrong_pages.lock() {
            *count += 1;
        }
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
            if let Some(record) = mocks
                .records
                .lock()
                .ok()
                .as_deref_mut()
                .and_then(|records| records.get_mut(index))
            {
                record.served_at = Instant::now();
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

    const SERVER: &str = "http://127.0.0.1:4321";

    fn linked(link: &str) -> MockResponse {
        let mut mock = MockResponse::default();
        mock.headers.insert("Link".into(), link.into());
        mock
    }

    fn page(link: &str) -> MockResponse {
        let mut mock = linked(link);
        mock.status = 200;
        mock
    }

    #[test]
    fn rewrites_the_fixture_origin_to_the_server() {
        let mock = linked("<http://localhost:3000/999/boards.json?page=2>; rel=\"next\"");
        let rewritten = rewrite_link(&mock, "http://localhost:3000", SERVER);
        assert_eq!(
            rewritten.headers["Link"],
            "<http://127.0.0.1:4321/999/boards.json?page=2>; rel=\"next\""
        );
    }

    #[test]
    fn leaves_foreign_prefix_sharing_and_downgraded_links_as_written() {
        for link in [
            "<https://evil.example.com/999/boards.json?page=2>; rel=\"next\"",
            "<http://fizzy.do/999/boards.json?page=2>; rel=\"next\"",
            "<https://fizzy.do:444/999/boards.json?page=2>; rel=\"next\"",
            "<https://fizzy.do.evil.example/x?next=https://fizzy.do/x>; rel=\"next\"",
        ] {
            let mock = linked(link);
            let rewritten = rewrite_link(&mock, "https://fizzy.do", SERVER);
            assert_eq!(rewritten.headers["Link"], link);
        }
    }

    #[test]
    fn keeps_commas_inside_targets_and_quoted_parameters() {
        let mock = linked(
            "<https://fizzy.do/a,b?x=1,2>; rel=\"next\"; title=\"one, two\", <https://fizzy.do/c>; rel=\"prev\"",
        );
        let rewritten = rewrite_link(&mock, "https://fizzy.do", SERVER);
        assert_eq!(
            rewritten.headers["Link"],
            "<http://127.0.0.1:4321/a,b?x=1,2>; rel=\"next\"; title=\"one, two\", <http://127.0.0.1:4321/c>; rel=\"prev\""
        );
    }

    #[test]
    fn resolves_network_path_references_by_their_own_origin() {
        let same = linked("<//fizzy.do/999/boards.json?page=2>; rel=\"next\"");
        let rewritten = rewrite_link(&same, "https://fizzy.do", SERVER);
        assert_eq!(
            rewritten.headers["Link"],
            "<http://127.0.0.1:4321/999/boards.json?page=2>; rel=\"next\""
        );
        let foreign = linked("<//evil.example/next>; rel=\"next\"");
        let rewritten = rewrite_link(&foreign, "https://fizzy.do", SERVER);
        assert_eq!(
            rewritten.headers["Link"],
            "<https://evil.example/next>; rel=\"next\""
        );
    }

    #[test]
    fn leaves_relative_links_alone() {
        let link = "</999/boards.json?page=2>; rel=\"next\"";
        let mock = linked(link);
        let rewritten = rewrite_link(&mock, "https://fizzy.do", SERVER);
        assert_eq!(rewritten.headers["Link"], link);
    }

    #[test]
    fn rewrites_only_the_matching_target_of_a_multi_link_header() {
        let mock = linked(
            "<https://fizzy.do/999/boards.json?page=2>; rel=\"next\", <https://other.example/x>; rel=\"prev\"",
        );
        let rewritten = rewrite_link(&mock, "https://fizzy.do", SERVER);
        assert_eq!(
            rewritten.headers["Link"],
            "<http://127.0.0.1:4321/999/boards.json?page=2>; rel=\"next\", <https://other.example/x>; rel=\"prev\""
        );
    }

    #[test]
    fn expects_the_page_the_previous_link_named() {
        let mocks = Mocks {
            base_url: SERVER.into(),
            responses: vec![
                page("</999/boards.json?page=2>; rel=\"next\""),
                MockResponse::default(),
                page("<https://evil.example.com/x>; rel=\"next\""),
                page("</999/boards.json?page=9>; rel=\"next\""),
                {
                    let mut retry = linked("</999/boards.json?page=9>; rel=\"next\"");
                    retry.status = 429;
                    retry
                },
            ],
            paginated: true,
            records: Arc::new(Mutex::new(Vec::new())),
            wrong_pages: Arc::new(Mutex::new(0)),
        };
        assert_eq!(expected_page(&mocks, 0, ""), None);
        assert_eq!(
            expected_page(&mocks, 1, "/999/boards.json").as_deref(),
            Some("/999/boards.json?page=2")
        );
        assert_eq!(expected_page(&mocks, 2, "/999/boards.json?page=2"), None);
        assert_eq!(expected_page(&mocks, 3, "/x"), None);
        assert_eq!(
            expected_page(&mocks, 4, "/999/boards.json?page=2").as_deref(),
            Some("/999/boards.json?page=9")
        );
        assert_eq!(expected_page(&mocks, 5, "/999/boards.json?page=9"), None);
    }

    #[test]
    fn resolves_a_relative_next_page_against_the_previous_request() {
        let mocks = Mocks {
            base_url: SERVER.into(),
            responses: vec![
                page("<?page=2>; rel=\"next\""),
                page("<next?page=3>; rel=\"next\""),
                MockResponse::default(),
            ],
            paginated: true,
            records: Arc::new(Mutex::new(Vec::new())),
            wrong_pages: Arc::new(Mutex::new(0)),
        };
        assert_eq!(
            expected_page(&mocks, 1, "/999/boards.json").as_deref(),
            Some("/999/boards.json?page=2")
        );
        assert_eq!(
            expected_page(&mocks, 2, "/999/boards.json?page=2").as_deref(),
            Some("/999/next?page=3")
        );
    }
}
