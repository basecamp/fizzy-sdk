//! The verbs for the parts of Fizzy the model does not describe. They take a path rather
//! than a route and hand back the answer undecoded, but everything else is what a modelled
//! call gets: the credentials, the hooks and the retries.
//!
//! A path here goes out as it was written; an [`AccountClient`] puts its account in front.

use serde::Serialize;
use url::Url;

use crate::client::{AccountClient, Client, RequestOptions, Response};
use crate::error::Error;
use crate::http::Method;
use crate::operation::Operation;
use crate::security::is_same_origin;

impl Client {
    /// Reads a path.
    pub async fn get(&self, path: &str) -> Result<Response, Error> {
        self.execute(self.raw(Method::GET, path)?).await
    }

    /// Reads a path under options of the caller's own.
    pub async fn get_with(&self, path: &str, options: &RequestOptions) -> Result<Response, Error> {
        self.execute(options.apply(self.raw(Method::GET, path)?))
            .await
    }

    /// Posts a JSON body. Sent once unless the options say the call is idempotent.
    pub async fn post(&self, path: &str, body: &impl Serialize) -> Result<Response, Error> {
        self.send_json(Method::POST, path, body, &RequestOptions::default())
            .await
    }

    /// Posts a JSON body under options of the caller's own.
    pub async fn post_with(
        &self,
        path: &str,
        body: &impl Serialize,
        options: &RequestOptions,
    ) -> Result<Response, Error> {
        self.send_json(Method::POST, path, body, options).await
    }

    /// Puts a JSON body.
    pub async fn put(&self, path: &str, body: &impl Serialize) -> Result<Response, Error> {
        self.send_json(Method::PUT, path, body, &RequestOptions::default())
            .await
    }

    /// Puts a JSON body under options of the caller's own.
    pub async fn put_with(
        &self,
        path: &str,
        body: &impl Serialize,
        options: &RequestOptions,
    ) -> Result<Response, Error> {
        self.send_json(Method::PUT, path, body, options).await
    }

    /// Patches with a JSON body.
    pub async fn patch(&self, path: &str, body: &impl Serialize) -> Result<Response, Error> {
        self.send_json(Method::PATCH, path, body, &RequestOptions::default())
            .await
    }

    /// Patches with a JSON body under options of the caller's own.
    pub async fn patch_with(
        &self,
        path: &str,
        body: &impl Serialize,
        options: &RequestOptions,
    ) -> Result<Response, Error> {
        self.send_json(Method::PATCH, path, body, options).await
    }

    /// Deletes a path.
    pub async fn delete(&self, path: &str) -> Result<Response, Error> {
        self.execute(self.raw(Method::DELETE, path)?).await
    }

    /// Deletes a path under options of the caller's own.
    pub async fn delete_with(
        &self,
        path: &str,
        options: &RequestOptions,
    ) -> Result<Response, Error> {
        self.execute(options.apply(self.raw(Method::DELETE, path)?))
            .await
    }

    /// An operation for a path the model does not cover. An absolute URL is sent as it
    /// stands, provided the credentials may travel to it; anything else is resolved
    /// against the base URL.
    pub(crate) fn raw(&self, method: Method, path: &str) -> Result<Operation, Error> {
        Ok(match self.absolute(path)? {
            Some(url) => Operation::at(method, url),
            None => Operation::raw(method, path.to_string()),
        })
    }

    /// The URL a path names when it already is one. HTTPS goes anywhere on the Fizzy
    /// origin; plain HTTP only back to the base URL's own host, which is how a Fizzy
    /// running on this machine is reached, and nowhere else — the credentials would go
    /// with it.
    fn absolute(&self, path: &str) -> Result<Option<Url>, Error> {
        if path.starts_with("https://") || path.starts_with("http://") {
            let url = Url::parse(path)?;
            if url.scheme() == "https" || is_same_origin(&url, self.base_url()) {
                Ok(Some(url))
            } else {
                Err(Error::usage(format!("URL must use HTTPS, got: {path}")))
            }
        } else {
            Ok(None)
        }
    }

    async fn send_json(
        &self,
        method: Method,
        path: &str,
        body: &impl Serialize,
        options: &RequestOptions,
    ) -> Result<Response, Error> {
        let mut operation = self.raw(method, path)?;
        operation.json(body)?;
        self.execute(options.apply(operation)).await
    }
}

impl AccountClient {
    /// Reads a path under the account.
    pub async fn get(&self, path: &str) -> Result<Response, Error> {
        self.client().get(&self.scoped(path)).await
    }

    /// Reads a path under the account, with options of the caller's own.
    pub async fn get_with(&self, path: &str, options: &RequestOptions) -> Result<Response, Error> {
        self.client().get_with(&self.scoped(path), options).await
    }

    /// Posts a JSON body under the account.
    pub async fn post(&self, path: &str, body: &impl Serialize) -> Result<Response, Error> {
        self.client().post(&self.scoped(path), body).await
    }

    /// Posts a JSON body under the account, with options of the caller's own.
    pub async fn post_with(
        &self,
        path: &str,
        body: &impl Serialize,
        options: &RequestOptions,
    ) -> Result<Response, Error> {
        self.client()
            .post_with(&self.scoped(path), body, options)
            .await
    }

    /// Puts a JSON body under the account.
    pub async fn put(&self, path: &str, body: &impl Serialize) -> Result<Response, Error> {
        self.client().put(&self.scoped(path), body).await
    }

    /// Puts a JSON body under the account, with options of the caller's own.
    pub async fn put_with(
        &self,
        path: &str,
        body: &impl Serialize,
        options: &RequestOptions,
    ) -> Result<Response, Error> {
        self.client()
            .put_with(&self.scoped(path), body, options)
            .await
    }

    /// Patches with a JSON body under the account.
    pub async fn patch(&self, path: &str, body: &impl Serialize) -> Result<Response, Error> {
        self.client().patch(&self.scoped(path), body).await
    }

    /// Patches with a JSON body under the account, with options of the caller's own.
    pub async fn patch_with(
        &self,
        path: &str,
        body: &impl Serialize,
        options: &RequestOptions,
    ) -> Result<Response, Error> {
        self.client()
            .patch_with(&self.scoped(path), body, options)
            .await
    }

    /// Deletes a path under the account.
    pub async fn delete(&self, path: &str) -> Result<Response, Error> {
        self.client().delete(&self.scoped(path)).await
    }

    /// Deletes a path under the account, with options of the caller's own.
    pub async fn delete_with(
        &self,
        path: &str,
        options: &RequestOptions,
    ) -> Result<Response, Error> {
        self.client().delete_with(&self.scoped(path), options).await
    }

    /// Reads a paginated path under the account to its end. See [`Client::get_all`].
    pub async fn get_all(&self, path: &str) -> Result<Vec<serde_json::Value>, Error> {
        self.client().get_all(&self.scoped(path)).await
    }

    /// Reads a paginated path under the account until `limit` items are in hand. See
    /// [`Client::get_all_with_limit`].
    pub async fn get_all_with_limit(
        &self,
        path: &str,
        limit: usize,
    ) -> Result<Vec<serde_json::Value>, Error> {
        self.client()
            .get_all_with_limit(&self.scoped(path), limit)
            .await
    }

    /// The path with the account in front. An absolute URL is left alone: it names where
    /// it goes already.
    fn scoped(&self, path: &str) -> String {
        if path.starts_with("https://") || path.starts_with("http://") {
            path.to_string()
        } else {
            format!("/{}/{}", self.account_id(), path.trim_start_matches('/'))
        }
    }
}
