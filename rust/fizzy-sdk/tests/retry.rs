//! The retry fixtures (`conformance/tests/retry.json`, `idempotency.json`) as unit tests, and
//! the per-route policy the fixtures cannot see: attempt counts from the behavior model,
//! the client's ceilings, and the policy carried across pages.

#![allow(clippy::unwrap_used, missing_docs)]

mod support;

use std::sync::Arc;
use std::time::{Duration, Instant};

use fizzy_sdk::models::{CreateBoardRequestContent, UpdateBoardRequestContent};
use fizzy_sdk::services::cards::ListCardsParams;
use fizzy_sdk::{ErrorCode, RequestOptions};
use serde_json::json;
use wiremock::matchers::{method, path, query_param};
use wiremock::{Mock, MockServer, ResponseTemplate};

use support::{Recorder, account, builder, client};

fn board() -> serde_json::Value {
    json!({"id": "b1", "name": "Test", "all_access": true, "created_at": "2026-01-01T00:00:00Z", "url": "https://fizzy.do/999/boards/b1"})
}

async fn mount_sequence(
    server: &MockServer,
    verb: &str,
    route: &str,
    statuses: &[u16],
    body: serde_json::Value,
) {
    for (index, status) in statuses.iter().enumerate() {
        let response = if *status < 300 {
            ResponseTemplate::new(*status).set_body_json(body.clone())
        } else {
            ResponseTemplate::new(*status).set_body_json(json!({"error": "Service unavailable"}))
        };
        let mock = Mock::given(method(verb))
            .and(path(route))
            .respond_with(response);
        let mock = if index + 1 == statuses.len() {
            mock
        } else {
            mock.up_to_n_times(1)
        };
        mock.mount(server).await;
    }
}

#[tokio::test]
async fn a_get_is_resent_on_503_up_to_the_routes_three_attempts_with_backoff() {
    let server = MockServer::start().await;
    mount_sequence(
        &server,
        "GET",
        "/999/boards.json",
        &[503, 503, 200],
        json!([]),
    )
    .await;
    let recorder = Arc::new(Recorder::default());
    let client = builder(&server).hooks(recorder.clone()).build().unwrap();
    let started = Instant::now();

    let boards = client
        .for_account("999")
        .unwrap()
        .boards()
        .list()
        .await
        .unwrap();

    assert!(boards.is_empty());
    assert_eq!(server.received_requests().await.unwrap().len(), 3);
    assert_eq!(recorder.retries(), [2, 3]);
    assert_eq!(recorder.requests(), [1, 2, 3]);
    assert!(
        started.elapsed() >= Duration::from_millis(40),
        "two waits of 20ms each"
    );
}

#[tokio::test]
async fn three_failures_exhaust_the_budget_and_the_last_answer_is_the_error() {
    let server = MockServer::start().await;
    mount_sequence(
        &server,
        "GET",
        "/999/boards.json",
        &[503, 503, 503],
        json!([]),
    )
    .await;

    let error = account(&server).boards().list().await.unwrap_err();

    assert_eq!(error.code(), ErrorCode::ApiError);
    assert_eq!(error.http_status(), Some(503));
    assert!(error.is_retryable());
    assert_eq!(server.received_requests().await.unwrap().len(), 3);
}

#[tokio::test]
async fn a_429_waits_out_its_retry_after_before_resending() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/999/boards/b1"))
        .respond_with(
            ResponseTemplate::new(429)
                .insert_header("Retry-After", "1")
                .set_body_json(json!({"error": "Rate limited"})),
        )
        .up_to_n_times(1)
        .mount(&server)
        .await;
    Mock::given(method("GET"))
        .and(path("/999/boards/b1"))
        .respond_with(ResponseTemplate::new(200).set_body_json(board()))
        .mount(&server)
        .await;
    let started = Instant::now();

    let board = account(&server).boards().get("b1").await.unwrap();

    assert_eq!(board.name, "Test");
    assert_eq!(server.received_requests().await.unwrap().len(), 2);
    assert!(started.elapsed() >= Duration::from_secs(1));
}

#[tokio::test]
async fn a_retry_after_past_the_ceiling_is_handed_back_rather_than_slept_through() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/999/boards/b1"))
        .respond_with(
            ResponseTemplate::new(429)
                .insert_header("Retry-After", "3600")
                .set_body_json(json!({"error": "Rate limited"})),
        )
        .mount(&server)
        .await;
    let client = builder(&server)
        .max_retry_after(Duration::from_secs(5))
        .build()
        .unwrap();
    let started = Instant::now();

    let error = client
        .for_account("999")
        .unwrap()
        .boards()
        .get("b1")
        .await
        .unwrap_err();

    assert_eq!(error.code(), ErrorCode::RateLimit);
    assert_eq!(error.hint(), Some("Try again in 3600 seconds"));
    assert_eq!(server.received_requests().await.unwrap().len(), 1);
    assert!(started.elapsed() < Duration::from_secs(1));
}

#[tokio::test]
async fn a_post_is_sent_once_and_its_503_is_the_answer() {
    let server = MockServer::start().await;
    mount_sequence(&server, "POST", "/999/boards.json", &[503], json!({})).await;

    let error = account(&server)
        .boards()
        .create(&CreateBoardRequestContent {
            name: "Test Board".into(),
            ..Default::default()
        })
        .await
        .unwrap_err();

    assert_eq!(error.http_status(), Some(503));
    assert_eq!(server.received_requests().await.unwrap().len(), 1);
}

#[tokio::test]
async fn an_idempotent_post_is_resent_like_a_get() {
    let server = MockServer::start().await;
    mount_sequence(
        &server,
        "POST",
        "/999/cards/7/closure.json",
        &[503, 204],
        json!(null),
    )
    .await;

    account(&server).cards().close(7).await.unwrap();

    assert_eq!(server.received_requests().await.unwrap().len(), 2);
}

#[tokio::test]
async fn a_404_is_never_resent() {
    let server = MockServer::start().await;
    mount_sequence(&server, "GET", "/999/boards/nope", &[404, 404], json!({})).await;

    let error = account(&server).boards().get("nope").await.unwrap_err();

    assert_eq!(error.code(), ErrorCode::NotFound);
    assert_eq!(server.received_requests().await.unwrap().len(), 1);
}

#[tokio::test]
async fn a_status_outside_the_routes_retry_on_is_never_resent() {
    let server = MockServer::start().await;
    mount_sequence(&server, "GET", "/999/boards/b1", &[502, 200], board()).await;

    let error = account(&server).boards().get("b1").await.unwrap_err();

    assert_eq!(error.http_status(), Some(502));
    assert_eq!(server.received_requests().await.unwrap().len(), 1);
}

#[tokio::test]
async fn patch_and_delete_are_resent() {
    let server = MockServer::start().await;
    mount_sequence(&server, "PATCH", "/999/boards/b1", &[503, 200], board()).await;
    mount_sequence(
        &server,
        "DELETE",
        "/999/boards/b1",
        &[503, 204],
        json!(null),
    )
    .await;
    let account = account(&server);

    account
        .boards()
        .update(
            "b1",
            &UpdateBoardRequestContent {
                name: Some("Updated".into()),
                ..Default::default()
            },
        )
        .await
        .unwrap();
    account.boards().delete("b1").await.unwrap();

    assert_eq!(server.received_requests().await.unwrap().len(), 4);
}

#[tokio::test]
async fn destroy_session_is_a_delete_the_model_sends_once() {
    let server = MockServer::start().await;
    mount_sequence(&server, "DELETE", "/session.json", &[503, 204], json!(null)).await;

    let error = client(&server).sessions().destroy().await.unwrap_err();

    assert_eq!(error.http_status(), Some(503));
    assert_eq!(server.received_requests().await.unwrap().len(), 1);
}

#[tokio::test]
async fn the_clients_max_attempts_is_a_ceiling_on_the_routes_attempts() {
    let server = MockServer::start().await;
    mount_sequence(
        &server,
        "GET",
        "/999/boards.json",
        &[503, 503, 200],
        json!([]),
    )
    .await;
    let client = builder(&server).max_attempts(2).build().unwrap();

    let error = client
        .for_account("999")
        .unwrap()
        .boards()
        .list()
        .await
        .unwrap_err();

    assert_eq!(error.http_status(), Some(503));
    assert_eq!(server.received_requests().await.unwrap().len(), 2);
}

#[tokio::test]
async fn a_raw_get_makes_three_attempts_by_default_and_the_last_429_is_a_rate_limit() {
    let server = MockServer::start().await;
    mount_sequence(
        &server,
        "GET",
        "/999/boards/b1",
        &[429, 429, 429, 200],
        board(),
    )
    .await;

    let error = account(&server).get("/boards/b1").await.unwrap_err();

    assert_eq!(error.code(), ErrorCode::RateLimit);
    assert_eq!(server.received_requests().await.unwrap().len(), 3);
}

#[tokio::test]
async fn raw_verbs_retry_everything_but_a_post_unless_told_otherwise() {
    let server = MockServer::start().await;
    mount_sequence(
        &server,
        "GET",
        "/999/anything",
        &[503, 200],
        json!({"ok": true}),
    )
    .await;
    mount_sequence(
        &server,
        "PATCH",
        "/999/anything",
        &[503, 200],
        json!({"ok": true}),
    )
    .await;
    mount_sequence(
        &server,
        "POST",
        "/999/anything",
        &[503, 503, 200],
        json!({"ok": true}),
    )
    .await;
    let account = account(&server);

    account.get("/anything").await.unwrap();
    account.patch("/anything", &json!({})).await.unwrap();
    let error = account.post("/anything", &json!({})).await.unwrap_err();
    assert_eq!(error.http_status(), Some(503));
    account
        .post_with("/anything", &json!({}), &RequestOptions::new().idempotent())
        .await
        .unwrap();

    assert_eq!(
        server.received_requests().await.unwrap().len(),
        2 + 2 + 1 + 2
    );
}

#[tokio::test]
async fn no_retry_sends_once_whatever_the_method() {
    let server = MockServer::start().await;
    mount_sequence(&server, "GET", "/999/anything", &[503, 200], json!({})).await;

    let error = account(&server)
        .get_with("/anything", &RequestOptions::new().no_retry())
        .await
        .unwrap_err();

    assert_eq!(error.http_status(), Some(503));
    assert_eq!(server.received_requests().await.unwrap().len(), 1);
}

#[tokio::test]
async fn every_page_of_a_walk_is_retried_under_the_first_pages_policy() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/999/cards.json"))
        .and(query_param("page", "2"))
        .respond_with(ResponseTemplate::new(503))
        .up_to_n_times(1)
        .mount(&server)
        .await;
    Mock::given(method("GET"))
        .and(path("/999/cards.json"))
        .and(query_param("page", "2"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!([])))
        .mount(&server)
        .await;
    Mock::given(method("GET"))
        .and(path("/999/cards.json"))
        .respond_with(
            ResponseTemplate::new(200)
                .insert_header(
                    "Link",
                    format!("<{}/999/cards.json?page=2>; rel=\"next\"", server.uri()).as_str(),
                )
                .set_body_json(json!([])),
        )
        .mount(&server)
        .await;
    let account = account(&server);

    let first = account
        .cards()
        .list(&ListCardsParams::default())
        .await
        .unwrap();
    let second = account.client().next_page(&first).await.unwrap().unwrap();

    assert!(second.is_empty());
    assert!(!second.has_next());
    assert_eq!(server.received_requests().await.unwrap().len(), 3);
}
