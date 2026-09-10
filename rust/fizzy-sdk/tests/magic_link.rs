//! The two-step magic-link login against a mock of what upstream Fizzy answers: the pending
//! token comes back on create, and goes back as a cookie with the code on redeem.

#![cfg(feature = "reqwest")]
#![allow(clippy::unwrap_used, missing_docs)]

use fizzy_sdk::{Client, Config, ErrorCode, MagicLinkFlow};
use serde_json::json;
use wiremock::matchers::{body_json, header, method, path};
use wiremock::{Mock, MockServer, ResponseTemplate};

#[tokio::test]
async fn the_flow_carries_the_pending_token_from_create_to_redeem() {
    let server = MockServer::start().await;
    Mock::given(method("POST"))
        .and(path("/session.json"))
        .and(body_json(json!({"email_address": "jane@example.com"})))
        .respond_with(
            ResponseTemplate::new(201)
                .set_body_json(json!({"pending_authentication_token": "pend-1"})),
        )
        .expect(1)
        .mount(&server)
        .await;
    Mock::given(method("POST"))
        .and(path("/session/magic_link.json"))
        .and(header("Cookie", "pending_authentication_token=pend-1"))
        .and(body_json(json!({"code": "ABC123", "token": "ABC123"})))
        .respond_with(
            ResponseTemplate::new(200).set_body_json(
                json!({"session_token": "sess-1", "requires_signup_completion": false}),
            ),
        )
        .expect(1)
        .mount(&server)
        .await;
    let flow = MagicLinkFlow::new(Config::default().with_base_url(server.uri())).unwrap();

    let pending = flow.create_session("jane@example.com").await.unwrap();
    assert_eq!(pending.pending_authentication_token.expose(), "pend-1");
    assert_eq!(flow.pending_token().unwrap().expose(), "pend-1");

    let session = flow.redeem("ABC123").await.unwrap();
    assert_eq!(session.session_token.expose(), "sess-1");
    assert!(!session.requires_signup_completion);
    assert!(flow.pending_token().is_none(), "the pending token is spent");
    let requests = server.received_requests().await.unwrap();
    assert!(
        requests
            .iter()
            .all(|request| request.headers.get("authorization").is_none())
    );
    server.verify().await;

    let client = Client::builder(Config::default().with_base_url(server.uri()))
        .session_token(session.session_token)
        .build()
        .unwrap();
    assert!(client.for_account("999").is_ok());
}

#[tokio::test]
async fn redeeming_without_a_pending_token_is_a_usage_error() {
    let server = MockServer::start().await;
    let flow = MagicLinkFlow::new(Config::default().with_base_url(server.uri())).unwrap();

    let error = flow.redeem("ABC123").await.unwrap_err();

    assert_eq!(error.code(), ErrorCode::Usage);
    assert!(server.received_requests().await.unwrap().is_empty());
}

#[tokio::test]
async fn a_resumed_flow_redeems_with_the_token_it_was_given() {
    let server = MockServer::start().await;
    Mock::given(method("POST"))
        .and(path("/session/magic_link.json"))
        .and(header("Cookie", "pending_authentication_token=pend-2"))
        .respond_with(
            ResponseTemplate::new(401).set_body_json(json!({"message": "Try another code."})),
        )
        .expect(1)
        .mount(&server)
        .await;
    let flow =
        MagicLinkFlow::resume(Config::default().with_base_url(server.uri()), "pend-2").unwrap();

    let error = flow.redeem("WRONG").await.unwrap_err();

    assert_eq!(error.code(), ErrorCode::AuthRequired);
    assert_eq!(error.hint(), Some("Try another code."));
    assert_eq!(
        server.received_requests().await.unwrap().len(),
        1,
        "a 401 is final"
    );
    server.verify().await;
}
