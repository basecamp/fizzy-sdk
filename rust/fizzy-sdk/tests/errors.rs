//! The error-mapping fixtures (`conformance/tests/error-mapping.json`) as unit tests.

#![cfg(feature = "reqwest")]
#![allow(clippy::unwrap_used, missing_docs)]

mod support;

use fizzy_sdk::ErrorCode;
use serde_json::json;
use wiremock::matchers::{method, path};
use wiremock::{Mock, MockServer, ResponseTemplate};

use support::account;

async fn answer(server: &MockServer, status: u16, body: serde_json::Value) {
    Mock::given(method("GET"))
        .and(path("/999/boards/b1"))
        .respond_with(
            ResponseTemplate::new(status)
                .insert_header("X-Request-Id", format!("req-{status}").as_str())
                .set_body_json(body),
        )
        .mount(server)
        .await;
}

#[tokio::test]
async fn statuses_map_to_the_shared_codes_with_the_request_id_and_body_kept() {
    let cases = [
        (401, ErrorCode::AuthRequired, 3, false),
        (403, ErrorCode::Forbidden, 4, false),
        (404, ErrorCode::NotFound, 2, false),
        (422, ErrorCode::Validation, 9, false),
        (429, ErrorCode::RateLimit, 5, true),
        (500, ErrorCode::ApiError, 7, true),
        (502, ErrorCode::ApiError, 7, true),
    ];
    for (status, code, exit, retryable) in cases {
        let server = MockServer::start().await;
        answer(
            &server,
            status,
            json!({"error": format!("Refused with {status}")}),
        )
        .await;

        let error = account(&server).boards().get("b1").await.unwrap_err();

        assert_eq!(error.code(), code, "{status}");
        assert_eq!(error.code().as_str(), code.as_str());
        assert_eq!(error.exit_code(), exit, "{status}");
        assert_eq!(error.http_status(), Some(status));
        assert_eq!(error.is_retryable(), retryable, "{status}");
        assert_eq!(error.request_id(), Some(format!("req-{status}").as_str()));
        assert!(error.body().is_some(), "{status} keeps its body");
        assert_eq!(
            error.body_json::<serde_json::Value>().unwrap()["error"],
            format!("Refused with {status}")
        );
    }
}

#[tokio::test]
async fn a_422_carries_the_servers_own_message_as_the_hint() {
    let server = MockServer::start().await;
    answer(&server, 422, json!({"error": "Name can't be blank"})).await;

    let error = account(&server).boards().get("b1").await.unwrap_err();

    assert_eq!(error.message(), "Validation failed");
    assert_eq!(error.hint(), Some("Name can't be blank"));
    assert_eq!(error.to_string(), "Validation failed: Name can't be blank");
}

#[tokio::test]
async fn a_403_on_a_write_names_the_scope() {
    let server = MockServer::start().await;
    Mock::given(method("DELETE"))
        .and(path("/999/boards/b1"))
        .respond_with(ResponseTemplate::new(403))
        .mount(&server)
        .await;

    let error = account(&server).boards().delete("b1").await.unwrap_err();

    assert_eq!(error.code(), ErrorCode::Forbidden);
    assert_eq!(error.hint(), Some("Re-authenticate with full scope"));
}

#[tokio::test]
async fn a_body_that_does_not_decode_keeps_the_status_and_reads_as_an_api_error() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/999/boards/b1"))
        .respond_with(ResponseTemplate::new(200).set_body_string("not json"))
        .mount(&server)
        .await;

    let error = account(&server).boards().get("b1").await.unwrap_err();

    assert_eq!(error.code(), ErrorCode::ApiError);
    assert!(error.hint().is_some());
}

#[tokio::test]
async fn nothing_answering_is_a_network_error() {
    let client = fizzy_sdk::Client::builder(
        fizzy_sdk::Config::default().with_base_url("http://127.0.0.1:1"),
    )
    .access_token("t")
    .max_attempts(1)
    .build()
    .unwrap();

    let error = client
        .for_account("999")
        .unwrap()
        .boards()
        .list()
        .await
        .unwrap_err();

    assert_eq!(error.code(), ErrorCode::Network);
    assert_eq!(error.exit_code(), 6);
    assert!(error.is_retryable());
}

#[tokio::test]
async fn a_decode_failure_keeps_the_status_and_request_id() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/999/boards/b1"))
        .respond_with(
            ResponseTemplate::new(200)
                .insert_header("X-Request-Id", "req-decode")
                .set_body_string("not json"),
        )
        .mount(&server)
        .await;

    let error = account(&server).boards().get("b1").await.unwrap_err();

    assert_eq!(error.code(), ErrorCode::ApiError);
    assert_eq!(error.http_status(), Some(200));
    assert_eq!(error.request_id(), Some("req-decode"));
}

#[tokio::test]
async fn a_503_past_the_retry_after_ceiling_still_says_how_long() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/999/boards/b1"))
        .respond_with(ResponseTemplate::new(503).insert_header("Retry-After", "3600"))
        .mount(&server)
        .await;

    let error = account(&server).boards().get("b1").await.unwrap_err();

    assert_eq!(error.http_status(), Some(503));
    assert_eq!(error.hint(), Some("Try again in 3600 seconds"));
    assert_eq!(server.received_requests().await.unwrap().len(), 1);
}
