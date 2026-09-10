//! The response body cap: an answer past it is refused, with the status kept on a failure.

#![allow(clippy::unwrap_used, missing_docs)]

mod support;

use fizzy_sdk::ErrorCode;
use wiremock::matchers::{method, path};
use wiremock::{Mock, MockServer, ResponseTemplate};

use support::builder;

#[tokio::test]
async fn a_body_past_the_cap_is_refused() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/999/boards.json"))
        .respond_with(ResponseTemplate::new(200).set_body_string("[".repeat(64)))
        .mount(&server)
        .await;
    let client = builder(&server)
        .max_response_body_bytes(32)
        .build()
        .unwrap();

    let error = client
        .for_account("999")
        .unwrap()
        .get("/boards.json")
        .await
        .unwrap_err();

    assert!(error.is_response_too_large());
    assert_eq!(error.code(), ErrorCode::ApiError);
}

#[tokio::test]
async fn a_failure_past_the_cap_still_reports_its_status() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/999/boards.json"))
        .respond_with(ResponseTemplate::new(422).set_body_string("x".repeat(64)))
        .mount(&server)
        .await;
    let client = builder(&server)
        .max_response_body_bytes(32)
        .build()
        .unwrap();

    let error = client
        .for_account("999")
        .unwrap()
        .get("/boards.json")
        .await
        .unwrap_err();

    assert!(error.is_response_too_large());
    assert_eq!(error.code(), ErrorCode::Validation);
    assert_eq!(error.http_status(), Some(422));
}
