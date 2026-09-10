//! The ETag cache: a repeated read revalidates and takes a 304 as the body it holds.

#![allow(clippy::unwrap_used, missing_docs)]

mod support;

use fizzy_sdk::cache::InMemoryCache;
use serde_json::json;
use wiremock::matchers::{header, method, path};
use wiremock::{Mock, MockServer, ResponseTemplate};

use support::builder;

#[tokio::test]
async fn a_304_answers_the_cached_body() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/999/boards.json"))
        .and(header("If-None-Match", "\"v1\""))
        .respond_with(ResponseTemplate::new(304))
        .mount(&server)
        .await;
    Mock::given(method("GET"))
        .and(path("/999/boards.json"))
        .respond_with(
            ResponseTemplate::new(200)
                .insert_header("ETag", "\"v1\"")
                .set_body_json(json!([{"id": "b1"}])),
        )
        .mount(&server)
        .await;
    let client = builder(&server)
        .cache(InMemoryCache::new())
        .build()
        .unwrap();
    let account = client.for_account("999").unwrap();

    let first = account.get("/boards.json").await.unwrap();
    let second = account.get("/boards.json").await.unwrap();

    assert!(!first.from_cache);
    assert!(second.from_cache);
    assert_eq!(second.status, 200);
    assert_eq!(second.body, first.body);
    let requests = server.received_requests().await.unwrap();
    assert_eq!(requests.len(), 2);
    assert!(requests[0].headers.get("if-none-match").is_none());
    assert_eq!(requests[1].headers.get("if-none-match").unwrap(), "\"v1\"");
}
