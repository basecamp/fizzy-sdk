//! The route table: one route per modelled operation, the facts the behavior model gives
//! them, and the router over their patterns.

#![allow(clippy::unwrap_used, missing_docs)]

use std::collections::HashSet;

use fizzy_sdk::routes::{self, Pagination, ROUTES};
use fizzy_sdk::url::router;

#[test]
fn every_modelled_route_is_listed_once() {
    let ids: HashSet<&str> = ROUTES.iter().map(|route| route.id).collect();
    assert_eq!(ROUTES.len(), 112);
    assert_eq!(ids.len(), ROUTES.len());
    let services: HashSet<&str> = ROUTES.iter().map(|route| route.service).collect();
    assert_eq!(services.len(), 18);
}

#[test]
fn routes_carry_the_behavior_models_facts() {
    assert!(routes::DESTROY_SESSION.retry.is_none());
    assert!(routes::CREATE_SESSION.retry.is_none());
    assert!(!routes::CREATE_SESSION.idempotent);
    assert!(routes::CLOSE_CARD.idempotent);
    let retry = routes::LIST_CARDS.retry.unwrap();
    assert_eq!(
        (retry.max, retry.base_delay_ms, retry.retry_on),
        (3, 1000, &[429, 500, 503][..])
    );
    assert_eq!(
        routes::LIST_CARDS.pagination,
        Pagination::Link { page_param: "page" }
    );
    assert_eq!(routes::GET_CARD.pagination, Pagination::None);
    assert!(routes::LIST_CARDS.readonly);
    assert!(!routes::CREATE_CARD.readonly);
    assert!(routes::GET_CARD.account_scoped);
    assert!(!routes::GET_MY_IDENTITY.account_scoped);
    assert_eq!(
        ROUTES.iter().filter(|route| !route.account_scoped).count(),
        9
    );
    assert_eq!(
        ROUTES
            .iter()
            .filter(|route| route.pagination != Pagination::None)
            .count(),
        13
    );
}

#[test]
fn filling_a_route_substitutes_and_encodes_its_parameters() {
    assert_eq!(
        routes::GET_BOARD.fill(Some("999"), &[&"b1"]),
        "/999/boards/b1"
    );
    assert_eq!(
        routes::GET_CARD.fill(Some("999"), &[&2_147_483_647]),
        "/999/cards/2147483647"
    );
    assert_eq!(
        routes::GET_BOARD.fill(Some("999"), &[&"9007199254740993"]),
        "/999/boards/9007199254740993"
    );
    assert_eq!(
        routes::GET_BOARD.fill(Some("a b"), &[&"c/d"]),
        "/a%20b/boards/c%2Fd"
    );
    assert_eq!(routes::GET_MY_IDENTITY.fill(None, &[]), "/my/identity.json");
}

#[test]
fn the_router_names_the_operation_a_pasted_url_refers_to() {
    let matched = router()
        .recognize("https://fizzy.do/999/cards/42/comments/c9")
        .unwrap();
    assert_eq!(matched.operation(), Some("GetComment"));
    assert_eq!(matched.resource_type, "comment");
    assert_eq!(matched.account_id(), Some("999"));
    assert_eq!(matched.resource_id(), Some("c9"));
}
