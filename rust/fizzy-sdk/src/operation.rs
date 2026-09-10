//! A request that has not been sent yet, and the retry policy it carries.

use std::borrow::Cow;
use std::fmt::Display;
use std::time::Duration;

use bytes::Bytes;
use serde::Serialize;
use url::Url;

use crate::error::Error;
use crate::http::{HeaderName, HeaderValue, Method};
use crate::observability::OperationInfo;
use crate::route::Route;

/// The statuses a call is resent on when nothing more specific says: what the behavior
/// model gives every retried operation.
pub const DEFAULT_RETRY_ON: &[u16] = &[429, 500, 503];

/// How many times an operation may be sent, and how the waits between attempts grow. Every
/// operation carries one: a modelled route's comes from the behavior model, a raw call's
/// from the client, and both are held under the client's own ceilings.
#[derive(Debug, Clone, PartialEq, Eq)]
#[non_exhaustive]
pub struct RetryPolicy {
    /// Total attempts, the first included. One means the call is never resent.
    pub attempts: u32,
    /// The first backoff, doubled after every attempt.
    pub base_delay: Duration,
    /// The statuses that are resent.
    pub retry_on: Cow<'static, [u16]>,
}

impl RetryPolicy {
    /// A call sent once and never resent.
    pub fn none() -> RetryPolicy {
        RetryPolicy {
            attempts: 1,
            base_delay: Duration::ZERO,
            retry_on: Cow::Borrowed(&[]),
        }
    }

    /// Whether an answer with this status is resent.
    pub fn retries(&self, status: u16) -> bool {
        self.attempts > 1 && self.retry_on.contains(&status)
    }
}

/// A request the client has not sent yet. Generated service methods build one from a
/// [`Route`]; [`crate::Client::request`] builds one for anything the model does not cover.
#[derive(Debug, Clone)]
pub struct Operation {
    pub(crate) id: Cow<'static, str>,
    pub(crate) info: OperationInfo,
    pub(crate) method: Method,
    pub(crate) path: String,
    pub(crate) url: Option<Url>,
    pub(crate) query: Vec<(String, String)>,
    pub(crate) headers: Vec<(HeaderName, HeaderValue)>,
    pub(crate) body: Option<Body>,
    pub(crate) idempotent: bool,
    /// `None` until the client sends it, when the client's defaults and ceilings are
    /// applied; `Some` once the route or the caller has said.
    pub(crate) retry: Option<RetryPolicy>,
    pub(crate) no_cache: bool,
}

#[derive(Debug, Clone)]
pub(crate) struct Body {
    pub(crate) content_type: String,
    pub(crate) bytes: Bytes,
}

impl Operation {
    pub(crate) fn for_route(
        route: &'static Route,
        account_id: Option<&str>,
        params: &[&dyn Display],
    ) -> Operation {
        let retry = route
            .retry
            .map_or_else(RetryPolicy::none, |retry| RetryPolicy {
                attempts: retry.max,
                base_delay: Duration::from_millis(retry.base_delay_ms),
                retry_on: Cow::Borrowed(retry.retry_on),
            });
        Operation {
            id: Cow::Borrowed(route.id),
            info: OperationInfo {
                service: Cow::Borrowed(route.service),
                operation: Cow::Borrowed(route.id),
                resource_type: Cow::Borrowed(route.resource_type),
                is_mutation: !route.readonly,
                resource_id: None,
            },
            method: route.method.clone(),
            path: route.fill(account_id, params),
            url: None,
            query: Vec::new(),
            headers: Vec::new(),
            body: None,
            idempotent: route.idempotent,
            retry: Some(retry),
            no_cache: false,
        }
    }

    /// A call for a path the model does not cover. Everything but a POST is taken as safe
    /// to resend, which is how Fizzy's other SDKs treat their raw verbs; a POST is sent
    /// once unless [`Operation::idempotent`] says otherwise.
    pub(crate) fn raw(method: Method, path: String) -> Operation {
        let idempotent = method != Method::POST;
        let id = format!("{method} {path}");
        let info = OperationInfo {
            service: Cow::Borrowed("Raw"),
            operation: Cow::Owned(id.clone()),
            resource_type: Cow::Borrowed("raw"),
            is_mutation: method != Method::GET,
            resource_id: None,
        };
        Operation {
            id: Cow::Owned(id),
            info,
            method,
            path,
            url: None,
            query: Vec::new(),
            headers: Vec::new(),
            body: None,
            idempotent,
            retry: None,
            no_cache: false,
        }
    }

    pub(crate) fn at(method: Method, url: Url) -> Operation {
        let mut operation = Operation::raw(method, url.path().to_string());
        operation.url = Some(url);
        operation
    }

    /// The operation id, or `METHOD /path` for a raw call.
    pub fn id(&self) -> &str {
        &self.id
    }

    /// The HTTP method.
    pub fn method(&self) -> &Method {
        &self.method
    }

    /// The path, account and parameters filled in.
    pub fn path(&self) -> &str {
        &self.path
    }

    /// The retry policy the operation will be sent under, once one has been settled.
    pub fn retry_policy(&self) -> Option<&RetryPolicy> {
        self.retry.as_ref()
    }

    /// Adds a query parameter.
    pub fn query(&mut self, name: &str, value: impl Display) -> &mut Operation {
        self.query.push((name.to_string(), value.to_string()));
        self
    }

    /// Adds a query parameter when there is a value for it.
    pub fn query_optional<T: Display>(&mut self, name: &str, value: Option<&T>) -> &mut Operation {
        if let Some(value) = value {
            self.query(name, value);
        }
        self
    }

    /// Adds a query parameter once per value, the way Rails reads `ids[]=1&ids[]=2`.
    pub fn query_all<T: Display>(&mut self, name: &str, values: &[T]) -> &mut Operation {
        for value in values {
            self.query(name, value);
        }
        self
    }

    /// Adds a repeated query parameter when there are values for it.
    pub fn query_all_optional<T: Display>(
        &mut self,
        name: &str,
        values: Option<&[T]>,
    ) -> &mut Operation {
        if let Some(values) = values {
            self.query_all(name, values);
        }
        self
    }

    /// Adds a header of the caller's own. Credentials go on through the client's
    /// [`crate::AuthStrategy`], not here.
    pub fn header(&mut self, name: HeaderName, value: HeaderValue) -> &mut Operation {
        self.headers.push((name, value));
        self
    }

    /// Sends a JSON body.
    pub fn json<T: Serialize + ?Sized>(&mut self, body: &T) -> Result<&mut Operation, Error> {
        self.body_bytes("application/json", Bytes::from(serde_json::to_vec(body)?));
        Ok(self)
    }

    /// A body the caller encoded, for the representations the model does not describe.
    pub fn body_bytes(&mut self, content_type: impl Into<String>, bytes: Bytes) -> &mut Operation {
        self.body = Some(Body {
            content_type: content_type.into(),
            bytes,
        });
        self
    }

    /// Replaces the whole of what the operation announces itself as to the client's
    /// [`crate::observability::Hooks`].
    pub fn info(&mut self, info: OperationInfo) -> &mut Operation {
        self.info = info;
        self
    }

    /// Announces the operation as something other than the route it sends.
    pub fn operation_name(&mut self, name: impl Into<Cow<'static, str>>) -> &mut Operation {
        self.info.operation = name.into();
        self
    }

    /// Names the kind of record the operation acts on.
    pub fn resource_type(&mut self, resource_type: impl Into<Cow<'static, str>>) -> &mut Operation {
        self.info.resource_type = resource_type.into();
        self
    }

    /// Names the record the operation acts on. Generated methods set this from the path
    /// parameter that names it.
    pub fn resource_id(&mut self, resource_id: impl Display) -> &mut Operation {
        self.info.resource_id = Some(resource_id.to_string());
        self
    }

    /// Marks the operation as safe to resend, or not, regardless of its HTTP method. A POST
    /// marked idempotent is retried like a GET.
    pub fn idempotent(&mut self, idempotent: bool) -> &mut Operation {
        self.idempotent = idempotent;
        self
    }

    /// Sends the operation once, whatever the route or the client would have allowed.
    pub fn no_retry(&mut self) -> &mut Operation {
        self.retry = Some(RetryPolicy::none());
        self
    }

    /// Sends the operation under a policy of the caller's own. The client's ceilings still
    /// apply.
    pub fn retry(&mut self, policy: RetryPolicy) -> &mut Operation {
        self.retry = Some(policy);
        self
    }

    /// Reads past the response cache for this send, so the answer is Fizzy's own.
    pub fn no_cache(&mut self) -> &mut Operation {
        self.no_cache = true;
        self
    }
}
