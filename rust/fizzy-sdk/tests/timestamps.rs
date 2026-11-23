//! Timestamps at the typed request boundary: what a card body carries on the wire.

#![allow(clippy::unwrap_used)]

use fizzy_sdk::jiff::Timestamp;
use fizzy_sdk::models::CreateCardRequestContent;

#[test]
fn a_card_body_writes_its_timestamps_in_utc_at_the_shortest_precision() {
    let card = CreateCardRequestContent {
        title: "Imported".to_string(),
        board_id: "1".to_string(),
        created_at: Some(
            "2025-12-31T19:00:00.100-05:00"
                .parse::<Timestamp>()
                .unwrap(),
        ),
        ..Default::default()
    };
    let body = serde_json::to_value(&card).unwrap();
    assert_eq!(body["created_at"], "2026-01-01T00:00:00.1Z");
    assert!(body.get("last_active_at").is_none());
}

#[test]
fn a_card_body_reads_back_the_instant_it_wrote() {
    let sent: CreateCardRequestContent = serde_json::from_value(serde_json::json!({
        "title": "Imported",
        "board_id": "1",
        "created_at": "2026-01-01T00:00:00.123Z",
    }))
    .unwrap();
    let written = serde_json::to_value(&sent).unwrap();
    assert_eq!(written["created_at"], "2026-01-01T00:00:00.123Z");
}

/// Through the generated service, over HTTP: the card body that reaches Fizzy carries the
/// timestamp at the shortest precision, and the card Fizzy answers with reads back.
#[cfg(feature = "reqwest")]
#[tokio::test]
async fn a_created_card_sends_and_reads_its_timestamps() {
    use std::time::Duration;

    use fizzy_sdk::models::Card;
    use fizzy_sdk::{Client, Config};
    use wiremock::matchers::{body_partial_json, method, path};
    use wiremock::{Mock, MockServer, ResponseTemplate};

    let server = MockServer::start().await;
    Mock::given(method("POST"))
        .and(path("/999/cards.json"))
        .and(body_partial_json(serde_json::json!({
            "created_at": "2026-01-01T00:00:00.1Z",
        })))
        .respond_with(ResponseTemplate::new(200).set_body_json(serde_json::json!({
            "id": "1",
            "created_at": "2026-01-01T00:00:00.100Z",
        })))
        .expect(1)
        .mount(&server)
        .await;
    let client = Client::builder(Config::default().with_base_url(server.uri()))
        .access_token("test-token")
        .max_attempts(1)
        .max_jitter(Duration::ZERO)
        .build()
        .unwrap();
    let card = CreateCardRequestContent {
        title: "Imported".to_string(),
        board_id: "1".to_string(),
        created_at: Some("2026-01-01T00:00:00.100Z".parse::<Timestamp>().unwrap()),
        ..Default::default()
    };
    let answer: Card = client
        .for_account("999")
        .unwrap()
        .cards()
        .create(&card)
        .await
        .unwrap();
    assert_eq!(
        answer.created_at,
        "2026-01-01T00:00:00.1Z".parse::<Timestamp>().unwrap()
    );
    server.verify().await;
}
