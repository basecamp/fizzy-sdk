//! The transport the runner hands the SDK: the shipped reqwest client, wrapped so a request
//! bound anywhere but the mock server is refused before it leaves the machine and counted.
//! The SDK therefore sees every `Link` exactly as the fixture wrote it — a foreign host, a
//! downgraded scheme — and a wrong decision to follow one is observed, not enabled.

use std::fmt;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use async_trait::async_trait;
use bytes::Bytes;
use fizzy_sdk::Error;
use fizzy_sdk::http::{Body, HttpClient, Request, ReqwestClient, Response};
use url::Url;

pub struct Intercept {
    inner: ReqwestClient,
    allowed: Option<Url>,
    foreign: Arc<Mutex<usize>>,
}

#[derive(Debug)]
struct ForeignOrigin(String);

impl fmt::Display for ForeignOrigin {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "request to {} refused: not the mock server", self.0)
    }
}

impl std::error::Error for ForeignOrigin {}

impl Intercept {
    /// A transport that only reaches `allowed`. With `None`, nothing gets through: the case
    /// expects the client not to be built at all.
    pub fn new(allowed: Option<&str>) -> Result<(Intercept, Arc<Mutex<usize>>), Error> {
        let foreign = Arc::new(Mutex::new(0));
        let intercept = Intercept {
            inner: ReqwestClient::with_timeout(Duration::from_secs(30))?,
            allowed: allowed.and_then(|url| Url::parse(url).ok()),
            foreign: foreign.clone(),
        };
        Ok((intercept, foreign))
    }
}

#[async_trait]
impl HttpClient for Intercept {
    async fn send(&self, request: Request<Bytes>) -> Result<Response<Body>, Error> {
        let target = request.uri().to_string();
        let permitted = Url::parse(&target)
            .ok()
            .zip(self.allowed.as_ref())
            .is_some_and(|(url, allowed)| {
                url.scheme() == allowed.scheme()
                    && url.host_str() == allowed.host_str()
                    && url.port_or_known_default() == allowed.port_or_known_default()
            });
        if permitted {
            self.inner.send(request).await
        } else {
            if let Ok(mut count) = self.foreign.lock() {
                *count += 1;
            }
            Err(Error::network(ForeignOrigin(target)))
        }
    }
}
