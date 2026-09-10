//! How credentials go on a request. Fizzy takes a bearer token (`Authorization: Bearer`)
//! for API access tokens, or a session cookie (`Cookie: session_token=`) for a session
//! signed in through a magic link. There is no OAuth and no refresh: a 401 is final.

use async_trait::async_trait;
use bytes::Bytes;

use crate::error::Error;
use crate::http::header::{AUTHORIZATION, COOKIE};
use crate::http::{HeaderValue, Request};
use crate::types::SensitiveString;

/// The cookie a signed-in session is carried in.
pub const SESSION_COOKIE: &str = "session_token";

/// Supplies the token each request goes out with.
#[async_trait]
pub trait TokenProvider: Send + Sync {
    /// The token to send now.
    async fn access_token(&self) -> Result<String, Error>;
}

/// A fixed token, from an environment variable say. It prints as `[REDACTED]`, so a `{:?}`
/// of the provider — or of anything holding one — cannot put the token in a log.
#[derive(Debug, Clone)]
pub struct StaticTokenProvider {
    /// The token.
    pub token: SensitiveString,
}

impl StaticTokenProvider {
    /// Wraps a token.
    pub fn new(token: impl Into<SensitiveString>) -> StaticTokenProvider {
        StaticTokenProvider {
            token: token.into(),
        }
    }
}

#[async_trait]
impl TokenProvider for StaticTokenProvider {
    async fn access_token(&self) -> Result<String, Error> {
        if self.token.is_empty() {
            Err(Error::auth("no token configured"))
        } else {
            Ok(self.token.expose().to_string())
        }
    }
}

/// Puts credentials on a request. [`BearerAuth`] and [`CookieAuth`] are the two Fizzy
/// takes; anything else can plug in here.
#[async_trait]
pub trait AuthStrategy: Send + Sync {
    /// Adds whatever the request needs to be recognized.
    async fn authenticate(&self, request: &mut Request<Bytes>) -> Result<(), Error>;
}

/// `Authorization: Bearer <token>`, for API access tokens.
pub struct BearerAuth<P: TokenProvider> {
    provider: P,
}

impl<P: TokenProvider> BearerAuth<P> {
    /// Bearer auth over a provider.
    pub fn new(provider: P) -> BearerAuth<P> {
        BearerAuth { provider }
    }
}

#[async_trait]
impl<P: TokenProvider> AuthStrategy for BearerAuth<P> {
    async fn authenticate(&self, request: &mut Request<Bytes>) -> Result<(), Error> {
        let token = self.provider.access_token().await?;
        let value = HeaderValue::from_str(&format!("Bearer {token}"))
            .map_err(|_| Error::auth("access token is not a valid header value"))?;
        request.headers_mut().insert(AUTHORIZATION, value);
        Ok(())
    }
}

/// `Cookie: session_token=<token>`, for a session signed in through a magic link.
pub struct CookieAuth<P: TokenProvider> {
    provider: P,
}

impl<P: TokenProvider> CookieAuth<P> {
    /// Cookie auth over a provider.
    pub fn new(provider: P) -> CookieAuth<P> {
        CookieAuth { provider }
    }
}

#[async_trait]
impl<P: TokenProvider> AuthStrategy for CookieAuth<P> {
    async fn authenticate(&self, request: &mut Request<Bytes>) -> Result<(), Error> {
        let token = self.provider.access_token().await?;
        let value = HeaderValue::from_str(&format!("{SESSION_COOKIE}={token}"))
            .map_err(|_| Error::auth("session token is not a valid cookie value"))?;
        request.headers_mut().insert(COOKIE, value);
        Ok(())
    }
}

/// No credentials at all, for the calls that come before there are any: creating a session
/// and redeeming its magic link.
#[derive(Debug, Clone, Copy, Default)]
pub struct NoAuth;

#[async_trait]
impl AuthStrategy for NoAuth {
    async fn authenticate(&self, _request: &mut Request<Bytes>) -> Result<(), Error> {
        Ok(())
    }
}
