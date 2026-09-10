//! The account split: paths under `/{accountId}` come from `AccountClient`, the rest from
//! `Client`, and a route that needs an account says so rather than sending a broken path.

#![allow(clippy::unwrap_used, missing_docs)]

mod support;

use fizzy_sdk::models::UpdateMyTimezoneRequestContent;
use fizzy_sdk::{Config, ErrorCode};
use serde_json::json;
use wiremock::matchers::{body_json, method, path};
use wiremock::{Mock, MockServer, ResponseTemplate};

use support::{account, client};

#[tokio::test]
async fn raw_verbs_on_an_account_client_put_the_account_in_front() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/999/boards.json"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!([{"id": "b1"}])))
        .expect(2)
        .mount(&server)
        .await;
    let account = account(&server);

    let response = account.get("/boards.json").await.unwrap();
    assert_eq!(response.status, 200);
    assert_eq!(response.json::<serde_json::Value>().unwrap()[0]["id"], "b1");
    account.get("boards.json").await.unwrap();

    server.verify().await;
}

#[tokio::test]
async fn an_account_route_reached_without_an_account_is_a_usage_error() {
    let server = MockServer::start().await;
    let body = UpdateMyTimezoneRequestContent {
        timezone_name: "Europe/Madrid".into(),
    };

    let error = client(&server)
        .identity()
        .update_my_timezone(&body)
        .await
        .unwrap_err();

    assert_eq!(error.code(), ErrorCode::Usage);
    assert!(error.message().contains("UpdateMyTimezone"));
    assert!(server.received_requests().await.unwrap().is_empty());
}

#[tokio::test]
async fn the_same_mixed_service_works_under_an_account() {
    let server = MockServer::start().await;
    let body = UpdateMyTimezoneRequestContent {
        timezone_name: "Europe/Madrid".into(),
    };
    Mock::given(method("PATCH"))
        .and(path("/999/my/timezone.json"))
        .and(body_json(json!({"timezone_name": "Europe/Madrid"})))
        .respond_with(ResponseTemplate::new(204))
        .expect(1)
        .mount(&server)
        .await;

    account(&server)
        .identity()
        .update_my_timezone(&body)
        .await
        .unwrap();

    server.verify().await;
}

#[tokio::test]
async fn the_configured_account_is_the_default_scope() {
    let server = MockServer::start().await;
    let client = fizzy_sdk::Client::builder(
        Config::default()
            .with_base_url(server.uri())
            .with_account("42"),
    )
    .access_token("t")
    .build()
    .unwrap();
    assert_eq!(client.for_configured_account().unwrap().account_id(), "42");
    let none = fizzy_sdk::Client::builder(Config::default().with_base_url(server.uri()))
        .access_token("t")
        .build()
        .unwrap();
    assert_eq!(
        none.for_configured_account().unwrap_err().code(),
        ErrorCode::Usage
    );
}
