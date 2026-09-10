#![allow(dead_code, unreachable_pub, clippy::unwrap_used)]

use std::sync::Mutex;
use std::time::Duration;

use fizzy_sdk::observability::{Hooks, OperationInfo, OperationState, RequestInfo};
use fizzy_sdk::{AccountClient, Client, ClientBuilder, Config, Error};
use wiremock::MockServer;

pub const TOKEN: &str = "test-token";
pub const ACCOUNT: &str = "999";

/// A client pointed at the mock server. The waits are wound right down so a test that
/// exercises retries still runs in milliseconds, and the jitter is off so it is repeatable.
pub fn builder(server: &MockServer) -> ClientBuilder {
    Client::builder(Config::default().with_base_url(server.uri()))
        .access_token(TOKEN)
        .base_delay(Duration::from_millis(20))
        .max_delay(Duration::from_millis(20))
        .max_jitter(Duration::ZERO)
}

pub fn client(server: &MockServer) -> Client {
    builder(server).build().unwrap()
}

pub fn account(server: &MockServer) -> AccountClient {
    client(server).for_account(ACCOUNT).unwrap()
}

/// What each operation announced itself as, in the order they started, and how each
/// ended; and every retry the hooks were told about.
#[derive(Default)]
pub struct Recorder {
    pub started: Mutex<Vec<String>>,
    pub ended: Mutex<Vec<Option<u16>>>,
    pub retries: Mutex<Vec<u32>>,
    pub requests: Mutex<Vec<u32>>,
}

impl Recorder {
    pub fn started(&self) -> Vec<String> {
        self.started.lock().unwrap().clone()
    }

    pub fn ended(&self) -> Vec<Option<u16>> {
        self.ended.lock().unwrap().clone()
    }

    pub fn retries(&self) -> Vec<u32> {
        self.retries.lock().unwrap().clone()
    }

    pub fn requests(&self) -> Vec<u32> {
        self.requests.lock().unwrap().clone()
    }
}

impl Hooks for Recorder {
    fn on_operation_start(&self, op: &OperationInfo) -> OperationState {
        self.started
            .lock()
            .unwrap()
            .push(format!("{}.{}", op.service, op.operation));
        None
    }

    fn on_operation_end(
        &self,
        _op: &OperationInfo,
        _state: OperationState,
        outcome: Result<(), &Error>,
        _duration: Duration,
    ) {
        self.ended
            .lock()
            .unwrap()
            .push(outcome.err().and_then(Error::http_status));
    }

    fn on_request_start(&self, info: &RequestInfo) {
        self.requests.lock().unwrap().push(info.attempt);
    }

    fn on_retry(&self, _info: &RequestInfo, next_attempt: u32, _cause: &Error) {
        self.retries.lock().unwrap().push(next_attempt);
    }
}
