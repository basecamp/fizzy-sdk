//! The pagination and security fixtures (`conformance/tests/pagination.json`,
//! `security.json`) as unit tests, plus the typed walks the fixtures cannot see.

#![cfg(feature = "reqwest")]
#![allow(clippy::unwrap_used, missing_docs)]

mod support;

use fizzy_sdk::ErrorCode;
use fizzy_sdk::models::Board;
use futures_util::{StreamExt, TryStreamExt};
use serde_json::json;
use wiremock::matchers::{method, path, query_param, query_param_is_missing};
use wiremock::{Mock, MockServer, ResponseTemplate};

use support::{account, builder};

fn board(id: &str) -> serde_json::Value {
    json!({"id": id, "name": format!("Board {id}"), "all_access": true, "created_at": "2026-01-01T00:00:00Z", "url": format!("https://fizzy.do/999/boards/{id}")})
}

async fn page(
    server: &MockServer,
    number: Option<&str>,
    body: serde_json::Value,
    next: Option<String>,
) {
    let mut mock = Mock::given(method("GET")).and(path("/999/boards.json"));
    mock = match number {
        Some(number) => mock.and(query_param("page", number)),
        None => mock.and(query_param_is_missing("page")),
    };
    let mut response = ResponseTemplate::new(200).set_body_json(body);
    if let Some(next) = next {
        response = response.insert_header("Link", format!("<{next}>; rel=\"next\"").as_str());
    }
    mock.respond_with(response).mount(server).await;
}

#[tokio::test]
async fn get_all_follows_same_origin_links_and_stops_at_the_end() {
    let server = MockServer::start().await;
    page(
        &server,
        None,
        json!([board("1")]),
        Some(format!("{}/999/boards.json?page=2", server.uri())),
    )
    .await;
    page(
        &server,
        Some("2"),
        json!([board("2")]),
        Some("/999/boards.json?page=3".to_string()),
    )
    .await;
    page(&server, Some("3"), json!([board("3")]), None).await;

    let items = account(&server).get_all("/boards.json").await.unwrap();

    assert_eq!(items.len(), 3);
    assert_eq!(items[2]["id"], "3");
    assert_eq!(server.received_requests().await.unwrap().len(), 3);
}

#[tokio::test]
async fn a_limit_lands_on_exactly_that_many_items() {
    let server = MockServer::start().await;
    page(
        &server,
        None,
        json!([board("1"), board("2")]),
        Some("/999/boards.json?page=2".to_string()),
    )
    .await;
    page(
        &server,
        Some("2"),
        json!([board("3"), board("4")]),
        Some("/999/boards.json?page=3".to_string()),
    )
    .await;

    let items = account(&server)
        .get_all_with_limit("/boards.json", 3)
        .await
        .unwrap();

    assert_eq!(items.len(), 3);
    assert_eq!(server.received_requests().await.unwrap().len(), 2);
}

#[tokio::test]
async fn a_link_off_the_origin_is_refused_rather_than_followed() {
    let server = MockServer::start().await;
    page(
        &server,
        None,
        json!([board("1")]),
        Some("https://evil.example.com/999/boards.json?page=2".to_string()),
    )
    .await;

    let error = account(&server).get_all("/boards.json").await.unwrap_err();

    assert_eq!(error.code(), ErrorCode::Usage);
    assert_eq!(server.received_requests().await.unwrap().len(), 1);
}

#[tokio::test]
async fn a_typed_walk_keeps_the_records_typed_and_ends_with_none() {
    let server = MockServer::start().await;
    page(
        &server,
        None,
        json!([board("1")]),
        Some("/999/boards.json?page=2".to_string()),
    )
    .await;
    page(&server, Some("2"), json!([board("2")]), None).await;
    let account = account(&server);

    let first = account.boards().list().await.unwrap();
    assert_eq!(first.next_page(), Some("2"));
    assert!(first.has_next());
    let second = account.client().next_page(&first).await.unwrap().unwrap();
    assert_eq!(second[0].name, "Board 2");
    assert!(account.client().next_page(&second).await.unwrap().is_none());

    let refused = account
        .client()
        .next_page(&first.clone().map(|boards: Vec<Board>| boards))
        .await;
    assert!(refused.is_ok());
}

#[tokio::test]
async fn a_typed_link_off_the_origin_is_refused_too() {
    let server = MockServer::start().await;
    page(
        &server,
        None,
        json!([board("1")]),
        Some("https://evil.example.com/999/boards.json?page=2".to_string()),
    )
    .await;
    let account = account(&server);

    let first = account.boards().list().await.unwrap();
    let error = account.client().next_page(&first).await.unwrap_err();

    assert_eq!(error.code(), ErrorCode::Usage);
}

#[tokio::test]
async fn pages_and_items_stream_lazily_up_to_the_page_cap() {
    let server = MockServer::start().await;
    page(
        &server,
        None,
        json!([board("1")]),
        Some("/999/boards.json?page=2".to_string()),
    )
    .await;
    page(
        &server,
        Some("2"),
        json!([board("2"), board("3")]),
        Some("/999/boards.json?page=3".to_string()),
    )
    .await;
    page(&server, Some("3"), json!([board("4")]), None).await;
    let client = builder(&server).max_pages(2).build().unwrap();
    let account = client.for_account("999").unwrap();

    let first = account.boards().list().await.unwrap();
    let pages: Vec<_> = client.pages(first).try_collect().await.unwrap();
    assert_eq!(pages.len(), 2, "the cap stops the walk");

    let first = account.boards().list().await.unwrap();
    let names: Vec<String> = client
        .items(first)
        .map(|board| board.unwrap().name)
        .collect()
        .await;
    assert_eq!(names, ["Board 1", "Board 2", "Board 3"]);

    let mut count = 0;
    let first = account.boards().list().await.unwrap();
    client
        .each_page(first, |page| {
            count += page.len();
            true
        })
        .await
        .unwrap();
    assert_eq!(count, 3);
}

#[tokio::test]
async fn get_all_stops_at_the_page_cap() {
    let server = MockServer::start().await;
    page(
        &server,
        None,
        json!([board("1")]),
        Some("/999/boards.json?page=2".to_string()),
    )
    .await;
    page(
        &server,
        Some("2"),
        json!([board("2")]),
        Some("/999/boards.json?page=3".to_string()),
    )
    .await;
    page(&server, Some("3"), json!([board("3")]), None).await;
    let client = builder(&server).max_pages(2).build().unwrap();

    let items = client
        .for_account("999")
        .unwrap()
        .get_all("/boards.json")
        .await
        .unwrap();

    assert_eq!(items.len(), 2);
}

#[tokio::test]
async fn the_page_stream_yields_a_page_before_fetching_the_next() {
    let server = MockServer::start().await;
    page(
        &server,
        None,
        json!([board("1")]),
        Some("/999/boards.json?page=2".to_string()),
    )
    .await;
    page(&server, Some("2"), json!([board("2")]), None).await;
    let account = account(&server);

    let first = account.boards().list().await.unwrap();
    let mut pages = std::pin::pin!(account.client().pages(first));
    let one = pages.next().await.unwrap().unwrap();
    assert_eq!(one[0].name, "Board 1");
    assert_eq!(
        server.received_requests().await.unwrap().len(),
        1,
        "page 2 not fetched yet"
    );
    let two = pages.next().await.unwrap().unwrap();
    assert_eq!(two[0].name, "Board 2");
    assert!(pages.next().await.is_none());
    assert_eq!(server.received_requests().await.unwrap().len(), 2);
}
