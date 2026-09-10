//! What the hooks hear: one operation per call, one request per attempt, every retry, and
//! the gate that can turn a call away before it is sent.

#![allow(clippy::unwrap_used, missing_docs)]

mod support;

use std::sync::Arc;
use std::time::Duration;

use async_trait::async_trait;
use fizzy_sdk::error::Refusal;
use fizzy_sdk::observability::{ChainHooks, Hooks, NoopHooks, OperationInfo};
use fizzy_sdk::resilience::{BulkheadConfig, CircuitBreakerConfig, ResilienceConfig};
use fizzy_sdk::services::cards::ListCardsParams;
use fizzy_sdk::{Error, ErrorCode};
use serde_json::json;
use wiremock::matchers::{method, path};
use wiremock::{Mock, MockServer, ResponseTemplate};

use support::{Recorder, builder};

#[tokio::test]
async fn an_operation_announces_itself_once_and_each_attempt_separately() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/999/boards/b1"))
        .respond_with(ResponseTemplate::new(503))
        .up_to_n_times(1)
        .mount(&server)
        .await;
    Mock::given(method("GET"))
        .and(path("/999/boards/b1"))
        .respond_with(ResponseTemplate::new(404))
        .mount(&server)
        .await;
    let recorder = Arc::new(Recorder::default());
    let client = builder(&server).hooks(recorder.clone()).build().unwrap();

    let _ = client.for_account("999").unwrap().boards().get("b1").await;

    assert_eq!(recorder.started(), ["Boards.GetBoard"]);
    assert_eq!(recorder.ended(), [Some(404)]);
    assert_eq!(recorder.requests(), [1, 2]);
    assert_eq!(recorder.retries(), [2]);
}

struct Refusing;

#[async_trait]
impl Hooks for Refusing {
    async fn on_operation_gate(&self, op: &OperationInfo) -> Result<(), Error> {
        Err(Error::usage(format!("{} blocked", op.operation)))
    }
}

#[tokio::test]
async fn a_gate_that_refuses_stops_the_call_before_anything_is_sent() {
    let server = MockServer::start().await;
    let recorder = Arc::new(Recorder::default());
    let chain = ChainHooks::of(vec![
        recorder.clone(),
        Arc::new(Refusing),
        Arc::new(NoopHooks),
    ]);
    let client = builder(&server).hooks(chain).build().unwrap();

    let error = client
        .for_account("999")
        .unwrap()
        .boards()
        .list()
        .await
        .unwrap_err();

    assert_eq!(error.code(), ErrorCode::Usage);
    assert_eq!(error.message(), "ListBoards blocked");
    assert!(server.received_requests().await.unwrap().is_empty());
    assert!(recorder.started().is_empty());
}

#[tokio::test]
async fn the_circuit_breaker_opens_on_repeated_server_failures_per_operation() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/999/boards.json"))
        .respond_with(ResponseTemplate::new(500))
        .mount(&server)
        .await;
    Mock::given(method("GET"))
        .and(path("/999/cards.json"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!([])))
        .mount(&server)
        .await;
    let client = builder(&server)
        .max_retries(0)
        .circuit_breaker(CircuitBreakerConfig {
            failure_threshold: 2,
            ..CircuitBreakerConfig::default()
        })
        .build()
        .unwrap();
    let account = client.for_account("999").unwrap();

    account.boards().list().await.unwrap_err();
    account.boards().list().await.unwrap_err();
    let refused = account.boards().list().await.unwrap_err();

    assert_eq!(refused.refusal(), Some(Refusal::CircuitOpen));
    assert_eq!(refused.code(), ErrorCode::ApiError);
    assert_eq!(server.received_requests().await.unwrap().len(), 2);
    account
        .cards()
        .list(&ListCardsParams::default())
        .await
        .unwrap();
}

#[tokio::test]
async fn a_full_bulkhead_gives_its_permit_back_when_the_call_ends() {
    let server = MockServer::start().await;
    Mock::given(method("GET"))
        .and(path("/999/boards.json"))
        .respond_with(
            ResponseTemplate::new(200)
                .set_body_json(json!([]))
                .set_delay(Duration::from_millis(100)),
        )
        .mount(&server)
        .await;
    let client = builder(&server)
        .resilience(ResilienceConfig {
            bulkhead: Some(BulkheadConfig {
                max_concurrent: 1,
                max_wait: Duration::ZERO,
            }),
            ..ResilienceConfig::none()
        })
        .build()
        .unwrap();
    let account = client.for_account("999").unwrap();

    let boards = account.boards();
    let (first, second) = tokio::join!(boards.list(), async {
        tokio::time::sleep(Duration::from_millis(20)).await;
        account.boards().list().await
    });
    assert!(first.is_ok());
    assert_eq!(second.unwrap_err().refusal(), Some(Refusal::BulkheadFull));

    account.boards().list().await.unwrap();
}
