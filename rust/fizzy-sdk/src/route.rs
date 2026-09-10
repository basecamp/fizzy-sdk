//! The route table's row type: what the model says about one operation.

use std::fmt::Display;

use percent_encoding::{AsciiSet, NON_ALPHANUMERIC, utf8_percent_encode};

use crate::error::Error;
use crate::http::Method;

/// One API operation: its method, its path template and the behaviour the Smithy model
/// attaches to it. Every route the SDK knows lives in [`crate::routes`].
#[derive(Debug)]
#[non_exhaustive]
pub struct Route {
    /// The OpenAPI operation id: `ListBoards`.
    pub id: &'static str,
    /// The service handle whose method sends this route: `Boards`, `AccessTokens`.
    pub service: &'static str,
    /// The HTTP method.
    pub method: Method,
    /// The path as Fizzy serves it, `{param}` placeholders included.
    pub path: &'static str,
    /// The path without a `.json` suffix, for recognizing pasted URLs.
    pub pattern: &'static str,
    /// The path starts with `/{accountId}`, which [`Route::fill`] takes first.
    pub account_scoped: bool,
    /// The kind of record the route acts on, snake_cased: `board`, `card`.
    pub resource_type: &'static str,
    /// The path parameters after the account, in order.
    pub params: &'static [RouteParam],
    /// Safe to resend.
    pub idempotent: bool,
    /// The route only reads; nothing it does changes anything.
    pub readonly: bool,
    /// How a list continues past its first page.
    pub pagination: Pagination,
    /// The retry budget, or `None` for a route that is sent once and never resent.
    pub retry: Option<Retry>,
}

/// One `{param}` in a route's path.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub struct RouteParam {
    /// The name inside the braces.
    pub name: &'static str,
    /// Where it sits.
    pub role: ParamRole,
    /// How it is typed.
    pub kind: ParamKind,
}

/// Where a path parameter sits: the last segment names the record itself, anything
/// before it names a parent.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub enum ParamRole {
    /// A parent's id.
    Parent,
    /// The record's own id.
    Recording,
}

/// The scalar types a path parameter takes.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub enum ParamKind {
    /// A string, sent verbatim.
    String,
    /// A boolean.
    Bool,
    /// A 32-bit integer.
    Int32,
    /// A 64-bit integer.
    Int64,
}

/// How a list continues past its first page.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub enum Pagination {
    /// The answer is complete.
    None,
    /// The answer carries a `Link: <…>; rel="next"` header naming the next page.
    Link {
        /// The query parameter that carries the page cursor.
        page_param: &'static str,
    },
}

/// The retry budget the behavior model gives a route.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub struct Retry {
    /// Total attempts, the first included.
    pub max: u32,
    /// The first backoff, in milliseconds, doubled after every attempt.
    pub base_delay_ms: u64,
    /// The statuses that are resent.
    pub retry_on: &'static [u16],
}

const PATH_SEGMENT: &AsciiSet = &NON_ALPHANUMERIC
    .remove(b'-')
    .remove(b'_')
    .remove(b'.')
    .remove(b'~');

impl Route {
    /// Substitutes the path parameters, in order, percent-encoding each value. An
    /// account-scoped route takes the account first.
    ///
    /// # Panics
    ///
    /// When `values` is not exactly as long as [`Route::params`] (plus one for the account
    /// on an account-scoped route). A short list would leave a `{param}` in the path and
    /// send it to Fizzy as written, which is worse than stopping; every generated caller
    /// passes the right count, so reaching this means the call was built by hand and built
    /// wrong.
    pub fn fill(&self, account_id: Option<&str>, values: &[&dyn Display]) -> String {
        match self.try_fill(account_id, values) {
            Ok(path) => path,
            Err(error) => panic!("{error}"),
        }
    }

    /// [`Route::fill`] as a `Result`: a wrong parameter count, a missing account or a value
    /// that is not one path segment is a usage error rather than a panic, for a caller
    /// building the operation by hand.
    pub fn try_fill(
        &self,
        account_id: Option<&str>,
        values: &[&dyn Display],
    ) -> Result<String, Error> {
        if values.len() != self.params.len() {
            return Err(Error::usage(format!(
                "{} takes {} path parameters, got {}",
                self.id,
                self.params.len(),
                values.len()
            )));
        }
        if account_id.is_some() != self.account_scoped {
            return Err(Error::usage(format!(
                "{} {} an account",
                self.id,
                if self.account_scoped {
                    "needs"
                } else {
                    "does not take"
                }
            )));
        }
        for value in values {
            let value = value.to_string();
            if value.is_empty() || value == "." || value == ".." {
                return Err(Error::usage(format!(
                    "{}: {value:?} is not a path parameter value",
                    self.id
                )));
            }
        }
        let mut path = self.path.to_string();
        if let Some(account_id) = account_id {
            path = path.replace("{accountId}", &encode(account_id));
        }
        for (param, value) in self.params.iter().zip(values) {
            path = path.replace(&format!("{{{}}}", param.name), &encode(&value.to_string()));
        }
        Ok(path)
    }

    /// Matches a path against the route's pattern and answers the captured parameters, the
    /// account included.
    pub fn recognize(&self, path: &str) -> Option<Vec<(&'static str, String)>> {
        let pattern_segments: Vec<&str> = self.pattern.split('/').collect();
        let path_segments: Vec<&str> = path.split('/').collect();
        if pattern_segments.len() != path_segments.len() {
            return None;
        }
        let mut params = Vec::new();
        for (pattern, actual) in pattern_segments.iter().zip(&path_segments) {
            if let Some(name) = pattern
                .strip_prefix('{')
                .and_then(|rest| rest.strip_suffix('}'))
            {
                if actual.is_empty() {
                    return None;
                }
                let name = if name == "accountId" {
                    "accountId"
                } else {
                    self.params.iter().find(|param| param.name == name)?.name
                };
                params.push((name, (*actual).to_string()));
            } else if pattern != actual {
                return None;
            }
        }
        Some(params)
    }

    /// The retry budget as attempts, delay and statuses; `None` for a route sent once.
    pub fn retry(&self) -> Option<Retry> {
        self.retry
    }
}

/// Percent-encodes one path segment.
pub(crate) fn encode(value: &str) -> String {
    utf8_percent_encode(value, PATH_SEGMENT).to_string()
}
