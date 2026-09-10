//! The Rust client for the [Fizzy](https://fizzy.do) API.
//!
//! Types, routes and service methods are generated from the Smithy model in the
//! repository's `spec/` directory; everything else in this crate is the plumbing they
//! share: authentication, retries, redirects, the response cache, pagination and the
//! account scope. All of it sends through one [`http::HttpClient`], which an application
//! may replace with its own; the `reqwest` feature, on by default, ships one.
//!
//! ```no_run
//! use fizzy_sdk::{Client, Config};
//!
//! # async fn run() -> Result<(), fizzy_sdk::Error> {
//! let token = std::env::var("FIZZY_TOKEN").unwrap_or_default();
//! let client = Client::builder(Config::default().with_env())
//!     .access_token(token)
//!     .build()?;
//! let account = client.for_account("999")?;
//! for board in account.boards().list().await?.iter() {
//!     println!("{} ({})", board.name, board.id);
//! }
//! # Ok(())
//! # }
//! ```

#![forbid(unsafe_code)]
#![cfg_attr(docsrs, feature(doc_cfg))]

pub mod auth;
pub mod cache;
pub mod client;
pub mod config;
pub mod error;
mod generated;
pub mod http;
pub mod magic_link;
pub mod observability;
pub mod operation;
pub mod pagination;
mod raw;
pub mod resilience;
pub mod route;
pub mod security;
mod trace;
pub mod types;
pub mod url;
pub mod version;
pub mod webhooks;

pub use auth::{AuthStrategy, BearerAuth, CookieAuth, NoAuth, StaticTokenProvider, TokenProvider};
pub use client::{AccountClient, Client, ClientBuilder, RequestOptions, Response, Scope};
pub use config::Config;
pub use error::{Error, ErrorCode};
pub use http::HttpClient;
pub use magic_link::MagicLinkFlow;
pub use operation::Operation;
pub use pagination::Page;
pub use types::{DateTime, SensitiveString};
pub use version::{API_VERSION, VERSION};

/// The request and response types Fizzy speaks, generated from the model.
pub mod models {
    pub use crate::generated::types::*;
}

/// Every modelled route, generated from the model.
pub mod routes {
    pub use crate::generated::routes::*;
    pub use crate::route::{Pagination, ParamKind, ParamRole, Retry, Route, RouteParam};
}

/// The service handles, one per group of operations, generated from the model.
pub mod services {
    pub use crate::generated::services::*;
}

/// Which fields of which types the model marks sensitive, generated from the model.
pub mod redaction {
    pub use crate::generated::redaction::PATHS;
}

/// Runs the README's code fences as doctests, so the crates.io landing page cannot drift
/// from the API it describes.
#[cfg(doctest)]
#[doc = include_str!("../README.md")]
pub struct ReadmeDoctests;
