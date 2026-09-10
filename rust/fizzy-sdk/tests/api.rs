//! The guarantees a caller leans on without reading the code: what is `Send + Sync`, what
//! is `Clone`, and that a returned future can cross threads.

#![allow(clippy::unwrap_used, missing_docs)]

use fizzy_sdk::{AccountClient, Client, Config, Error, MagicLinkFlow, Page, Response};

fn send_sync<T: Send + Sync>() {}
fn clone<T: Clone>() {}
fn is_send<F: Send>(_: F) {}

#[test]
fn public_types_are_send_sync_and_clients_are_clone() {
    send_sync::<Client>();
    send_sync::<AccountClient>();
    send_sync::<Error>();
    send_sync::<Response>();
    send_sync::<Page<Vec<String>>>();
    send_sync::<MagicLinkFlow>();
    clone::<Client>();
    clone::<AccountClient>();
    clone::<Config>();
}

#[test]
fn futures_are_send() {
    let client = Client::builder(Config::default())
        .access_token("t")
        .build()
        .unwrap();
    let account = client.for_account("999").unwrap();
    is_send(async move {
        let _ = account.boards().list().await;
        let _ = client.identity().get_my_identity().await;
    });
}

#[test]
fn error_implements_the_std_traits() {
    let error: Box<dyn std::error::Error + Send + Sync> = Box::new(Error::usage("x"));
    assert_eq!(error.to_string(), "x");
}
