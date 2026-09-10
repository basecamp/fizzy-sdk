//! The security and auth fixtures (`conformance/tests/security.json`, `auth.json`) as unit
//! tests: HTTPS enforcement, the credentials each strategy sends, the `User-Agent`, and
//! what the hooks are allowed to see.

#![cfg(feature = "reqwest")]
#![allow(clippy::unwrap_used, missing_docs)]

mod support;

use fizzy_sdk::security::redact_headers;
use fizzy_sdk::{API_VERSION, Client, Config, ErrorCode, VERSION};
use serde_json::json;
use wiremock::matchers::{header, method, path};
use wiremock::{Mock, MockServer, ResponseTemplate};

use support::{TOKEN, account};

#[test]
fn a_plain_http_origin_off_this_machine_is_refused_at_build_time() {
    let error = Client::builder(Config::default().with_base_url("http://evil.example.com"))
        .access_token("t")
        .build()
        .err()
        .unwrap();

    assert_eq!(error.code(), ErrorCode::Usage);
    assert_eq!(error.code().as_str(), "usage");
}

#[test]
fn localhost_may_be_plain_http() {
    assert!(
        Client::builder(Config::default().with_base_url("http://localhost:3000"))
            .access_token("t")
            .build()
            .is_ok()
    );
    assert!(
        Client::builder(Config::default().with_base_url("http://127.0.0.1:3000"))
            .access_token("t")
            .build()
            .is_ok()
    );
}

#[tokio::test]
async fn a_bearer_token_and_the_user_agent_go_on_every_request() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/999/boards.json"))
        .and(header("Authorization", format!("Bearer {TOKEN}").as_str()))
        .and(header(
            "User-Agent",
            format!("fizzy-sdk-rust/{VERSION} (api:{API_VERSION})").as_str(),
        ))
        .and(header("Accept", "application/json"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!([])))
        .expect(1)
        .mount(&server)
        .await;

    account(&server).boards().list().await.unwrap();

    server.verify().await;
}

#[tokio::test]
async fn a_session_token_goes_out_as_a_cookie() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/my/identity.json"))
        .and(header("Cookie", "session_token=sess-1"))
        .respond_with(ResponseTemplate::new(200).set_body_json(
            json!({"id": "i1", "name": "Jane", "email_address": "jane@example.com"}),
        ))
        .expect(1)
        .mount(&server)
        .await;
    let client = Client::builder(Config::default().with_base_url(server.uri()))
        .session_token("sess-1")
        .build()
        .unwrap();

    let identity = client.identity().get_my_identity().await.unwrap();

    assert_eq!(
        identity.email_address.as_ref().unwrap().expose(),
        "jane@example.com"
    );
    assert_eq!(format!("{:?}", identity.email_address), "Some([REDACTED])");
    assert!(!format!("{identity:?}").contains("jane@example.com"));
    server.verify().await;
}

#[test]
fn credentials_never_reach_a_log_through_the_redactor() {
    let mut headers = fizzy_sdk::http::HeaderMap::new();
    headers.insert("authorization", "Bearer secret".parse().unwrap());
    headers.insert("cookie", "session_token=secret".parse().unwrap());
    headers.insert("accept", "application/json".parse().unwrap());
    let redacted = redact_headers(&headers);
    assert_eq!(redacted["authorization"], "[REDACTED]");
    assert_eq!(redacted["cookie"], "[REDACTED]");
    assert_eq!(redacted["accept"], "application/json");
}

#[test]
fn an_empty_token_is_refused_before_anything_is_sent() {
    let client = Client::builder(Config::default())
        .access_token("")
        .build()
        .unwrap();
    let error = tokio::runtime::Runtime::new()
        .unwrap()
        .block_on(client.identity().get_my_identity())
        .unwrap_err();
    assert_eq!(error.code(), ErrorCode::AuthRequired);
}

#[tokio::test]
async fn an_absolute_url_off_the_origin_is_refused_before_credentials_go_anywhere() {
    let server = MockServer::start().await;
    let error = account(&server)
        .get("https://other.example.com/999/boards.json")
        .await
        .unwrap_err();
    assert_eq!(error.code(), ErrorCode::Usage);
    assert!(server.received_requests().await.unwrap().is_empty());
    let same = format!("{}/999/boards.json", server.uri());
    Mock::given(method("GET"))
        .and(path("/999/boards.json"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!([])))
        .mount(&server)
        .await;
    assert!(account(&server).get(&same).await.is_ok());
}

#[tokio::test]
async fn an_absolute_url_off_the_origin_carrying_credentials_is_refused_without_echoing_them() {
    let server = MockServer::start().await;
    let error = account(&server)
        .get("https://user:s3cret@other.example.com/999/boards.json?token=s3cret")
        .await
        .unwrap_err();
    assert_eq!(error.code(), ErrorCode::Usage);
    assert!(!error.to_string().contains("s3cret"));
    assert!(server.received_requests().await.unwrap().is_empty());
}

#[test]
fn a_base_url_with_credentials_is_refused() {
    let error = Client::builder(Config::default().with_base_url("https://user:secret@fizzy.do"))
        .access_token("t")
        .build()
        .err()
        .unwrap();
    assert_eq!(error.code(), ErrorCode::Usage);
    assert!(!error.to_string().contains("secret"));
}

#[tokio::test]
async fn cookie_values_are_escaped_the_way_rack_reads_them() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/my/identity.json"))
        .and(header("Cookie", "session_token=a%2Bb%2Fc%3D%3D"))
        .respond_with(ResponseTemplate::new(200).set_body_json(
            json!({"id": "i1", "name": "Jane", "email_address": "jane@example.com"}),
        ))
        .expect(1)
        .mount(&server)
        .await;
    let client = Client::builder(Config::default().with_base_url(server.uri()))
        .session_token("a+b/c==")
        .build()
        .unwrap();

    client.identity().get_my_identity().await.unwrap();

    server.verify().await;
}

#[tokio::test]
async fn an_uppercase_scheme_or_a_scheme_relative_path_does_not_slip_past_the_origin_check() {
    let server = MockServer::start().await;
    let client = account(&server).client().clone();
    for path in ["HTTPS://evil.example.com/x", "Http://evil.example.com/x"] {
        let error = client.get(path).await.unwrap_err();
        assert_eq!(error.code(), ErrorCode::Usage, "{path}");
    }
    assert!(server.received_requests().await.unwrap().is_empty());
}

#[tokio::test]
async fn a_session_answer_prints_without_its_token() {
    let server = MockServer::start().await;
    Mock::given(method("POST"))
        .and(path("/session/magic_link.json"))
        .respond_with(ResponseTemplate::new(200).set_body_json(
            json!({"session_token": "sess-secret", "requires_signup_completion": false}),
        ))
        .mount(&server)
        .await;
    let flow =
        fizzy_sdk::MagicLinkFlow::resume(Config::default().with_base_url(server.uri()), "pend")
            .unwrap();

    let session = flow.redeem("CODE").await.unwrap();

    assert_eq!(session.session_token.expose(), "sess-secret");
    assert!(!format!("{session:?}").contains("sess-secret"));
}
