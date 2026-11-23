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
