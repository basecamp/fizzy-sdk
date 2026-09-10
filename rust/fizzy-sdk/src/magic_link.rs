//! Signing in without a password. Fizzy sends a code to an email address and, once the
//! person types it back, hands out a session token for [`crate::CookieAuth`].
//!
//! The two steps are one exchange as far as Fizzy is concerned: creating the session sets
//! a `pending_authentication_token` cookie naming the address the code went to, and
//! redeeming the code has to send that cookie back or the code is refused. The flow keeps
//! the token between the calls, and hands it out for a caller that has to finish in
//! another process — a CLI that prompts for the code on its next run.
//!
//! ```no_run
//! use fizzy_sdk::{Client, Config, MagicLinkFlow};
//!
//! # async fn run(code: &str) -> Result<(), fizzy_sdk::Error> {
//! let flow = MagicLinkFlow::new(Config::default())?;
//! flow.create_session("jane@example.com").await?;
//! // ... the person reads the code out of their email ...
//! let session = flow.redeem(code).await?;
//! let client = Client::builder(Config::default())
//!     .session_token(session.session_token.clone())
//!     .build()?;
//! # let _ = client;
//! # Ok(())
//! # }
//! ```
//!
//! # Where this parts company with the model
//!
//! The Smithy model spells `RedeemMagicLink`'s body as `{"token": …}` and says nothing of
//! the cookie; upstream Fizzy reads `code` and requires the cookie. The flow follows
//! upstream, since that is what answers, and sends both spellings of the code so it also
//! works against a server built from the model as written. The generated
//! [`crate::services::sessions::SessionsService::redeem_magic_link`] is the model's shape and
//! cannot complete a login on its own until the model catches up.

use std::sync::Mutex;

use serde::Serialize;

use crate::auth::NoAuth;
use crate::client::{Client, ClientBuilder};
use crate::config::Config;
use crate::error::Error;
use crate::generated::routes;
use crate::generated::types::{
    CreateSessionRequestContent, PendingAuthentication, SessionAuthorization,
};
use crate::http::HeaderValue;
use crate::http::header::COOKIE;
use crate::types::SensitiveString;

/// The cookie a pending sign-in is carried in between creating the session and redeeming
/// the code.
pub const PENDING_COOKIE: &str = "pending_authentication_token";

/// A sign-in in progress.
pub struct MagicLinkFlow {
    client: Client,
    pending: Mutex<Option<SensitiveString>>,
}

#[derive(Serialize)]
struct Redeem<'a> {
    code: &'a str,
    token: &'a str,
}

impl MagicLinkFlow {
    /// A flow against the configured origin, sending no credentials: there are none yet.
    pub fn new(config: Config) -> Result<MagicLinkFlow, Error> {
        MagicLinkFlow::from_builder(Client::builder(config))
    }

    /// A flow over a builder of the caller's own — a custom HTTP client, hooks — whose
    /// credentials are replaced with none.
    pub fn from_builder(builder: ClientBuilder) -> Result<MagicLinkFlow, Error> {
        Ok(MagicLinkFlow {
            client: builder.auth_strategy(NoAuth).build()?,
            pending: Mutex::new(None),
        })
    }

    /// A flow that picks up where another left off, with the pending token that one
    /// handed out through [`MagicLinkFlow::pending_token`].
    pub fn resume(
        config: Config,
        pending_token: impl Into<SensitiveString>,
    ) -> Result<MagicLinkFlow, Error> {
        let flow = MagicLinkFlow::new(config)?;
        *flow
            .pending
            .lock()
            .unwrap_or_else(std::sync::PoisonError::into_inner) = Some(pending_token.into());
        Ok(flow)
    }

    /// The client the flow sends through.
    pub fn client(&self) -> &Client {
        &self.client
    }

    /// Asks Fizzy to email a sign-in code to the address, and keeps the pending token the
    /// answer carries for [`MagicLinkFlow::redeem`].
    pub async fn create_session(
        &self,
        email_address: &str,
    ) -> Result<PendingAuthentication, Error> {
        let mut operation = self.client.operation(&routes::CREATE_SESSION, &[])?;
        operation.operation_name("MagicLinkCreateSession");
        operation.json(&CreateSessionRequestContent {
            email_address: SensitiveString::new(email_address),
        })?;
        let pending: PendingAuthentication = self.client.send(operation).await?;
        *self
            .pending
            .lock()
            .unwrap_or_else(std::sync::PoisonError::into_inner) = Some(SensitiveString::new(
            pending.pending_authentication_token.clone(),
        ));
        Ok(pending)
    }

    /// The token a pending sign-in is waiting on, for a caller that finishes the flow in
    /// another process.
    pub fn pending_token(&self) -> Option<SensitiveString> {
        self.pending
            .lock()
            .unwrap_or_else(std::sync::PoisonError::into_inner)
            .clone()
    }

    /// Sends the code back with the pending token, and answers the session Fizzy signed
    /// in. Without a pending token — no [`MagicLinkFlow::create_session`] before it, and
    /// nothing given to [`MagicLinkFlow::resume`] — there is nothing to redeem against.
    pub async fn redeem(&self, code: &str) -> Result<SessionAuthorization, Error> {
        let pending = self.pending_token().ok_or_else(|| {
            Error::usage_with_hint(
                "no sign-in is pending",
                "call create_session first, or resume with the pending token",
            )
        })?;
        let cookie = HeaderValue::from_str(&format!("{PENDING_COOKIE}={}", pending.expose()))
            .map_err(|_| Error::usage("pending token is not a valid cookie value"))?;
        let mut operation = self.client.operation(&routes::REDEEM_MAGIC_LINK, &[])?;
        operation.operation_name("MagicLinkRedeem");
        operation.header(COOKIE, cookie);
        operation.json(&Redeem { code, token: code })?;
        let session: SessionAuthorization = self.client.send(operation).await?;
        *self
            .pending
            .lock()
            .unwrap_or_else(std::sync::PoisonError::into_inner) = None;
        Ok(session)
    }
}
