//! Pages, the cursors between them, and the walks that read them all.

use std::ops::Deref;

use futures_util::Stream;
use futures_util::stream::{self, StreamExt};
use serde::de::DeserializeOwned;
use serde_json::Value;
use url::Url;

use crate::client::{Client, Response};
use crate::error::Error;
use crate::http::Method;
use crate::observability::OperationInfo;
use crate::operation::{Operation, RetryPolicy};
use crate::security::is_same_origin;

/// One page of a paginated read, with the cursor Fizzy handed out for the next one.
///
/// The page derefs to its value, so `page.iter()` on a page of boards reads the same as it
/// would on the `Vec<Board>` itself.
#[derive(Debug, Clone)]
pub struct Page<T> {
    value: T,
    next_url: Option<Url>,
    next_page: Option<String>,
    total_count: Option<u64>,
    /// What the read that produced this page announced itself as, so the reads that walk
    /// on from it can say the same.
    info: OperationInfo,
    /// The retry policy the first page was read under, so every page after it is too.
    retry: Option<RetryPolicy>,
}

impl<T> Page<T> {
    pub(crate) fn new(
        value: T,
        response: &Response,
        info: OperationInfo,
        retry: Option<RetryPolicy>,
    ) -> Page<T> {
        let next_url = response
            .headers
            .get("link")
            .and_then(|value| value.to_str().ok())
            .and_then(next_link)
            .and_then(|target| response.url.join(&target).ok());
        let next_page = next_url.as_ref().and_then(|url| {
            url.query_pairs()
                .find(|(name, _)| name == "page")
                .map(|(_, value)| value.into_owned())
        });
        let total_count = response
            .headers
            .get("x-total-count")
            .and_then(|value| value.to_str().ok())
            .and_then(|value| value.trim().parse().ok());
        Page {
            value,
            next_url,
            next_page,
            total_count,
            info,
            retry,
        }
    }

    pub(crate) fn info(&self) -> &OperationInfo {
        &self.info
    }

    pub(crate) fn retry(&self) -> Option<&RetryPolicy> {
        self.retry.as_ref()
    }

    /// The page's contents, owned.
    pub fn into_inner(self) -> T {
        self.value
    }

    /// The page's contents.
    pub fn value(&self) -> &T {
        &self.value
    }

    /// The opaque cursor for the page after this one, to pass as `page` on the same read.
    pub fn next_page(&self) -> Option<&str> {
        self.next_page.as_deref()
    }

    /// The URL of the page after this one, as Fizzy's `Link` header named it.
    pub fn next_url(&self) -> Option<&Url> {
        self.next_url.as_ref()
    }

    /// Whether Fizzy named a page after this one.
    pub fn has_next(&self) -> bool {
        self.next_url.is_some()
    }

    /// The `X-Total-Count` header, when the read carried one.
    pub fn total_count(&self) -> Option<u64> {
        self.total_count
    }

    /// The same page with its contents transformed.
    pub fn map<U>(self, f: impl FnOnce(T) -> U) -> Page<U> {
        Page {
            value: f(self.value),
            next_url: self.next_url,
            next_page: self.next_page,
            total_count: self.total_count,
            info: self.info,
            retry: self.retry,
        }
    }
}

impl<T> Deref for Page<T> {
    type Target = T;

    fn deref(&self) -> &T {
        &self.value
    }
}

impl Client {
    /// Reads the page after the given one, or `None` when Fizzy named no next page. A
    /// `Link` header pointing off the Fizzy origin is refused rather than followed. The
    /// read announces itself as the operation the first page came from and is sent under
    /// the same retry policy, so a whole walk shows up as one thing and is retried as one.
    pub async fn next_page<T: DeserializeOwned>(
        &self,
        page: &Page<T>,
    ) -> Result<Option<Page<T>>, Error> {
        match page.next_url() {
            None => Ok(None),
            Some(next) if !is_same_origin(next, self.base_url()) => Err(Error::usage(format!(
                "pagination Link header points to a different origin: {next}"
            ))),
            Some(next) => {
                let mut operation = Operation::at(Method::GET, next.clone());
                operation.info(page.info().clone());
                if let Some(retry) = page.retry() {
                    operation.retry(retry.clone());
                }
                self.send_page(operation).await.map(Some)
            }
        }
    }

    /// Reads every page after the first, up to the client's page limit, calling `visit`
    /// with each one. Stops early when `visit` answers `false`.
    pub async fn each_page<T: DeserializeOwned>(
        &self,
        first: Page<T>,
        mut visit: impl FnMut(&Page<T>) -> bool,
    ) -> Result<(), Error> {
        let mut page = first;
        let mut count = 1;
        while visit(&page) && count < self.max_pages() {
            match self.next_page(&page).await? {
                Some(next) => page = next,
                None => break,
            }
            count += 1;
        }
        Ok(())
    }

    /// The first page and every one after it, read lazily as the stream is polled, up to
    /// the client's page limit. A page that fails to read ends the stream with its error.
    pub fn pages<'a, T: DeserializeOwned + 'a>(
        &'a self,
        first: Page<T>,
    ) -> impl Stream<Item = Result<Page<T>, Error>> + 'a {
        let max_pages = self.max_pages();
        stream::try_unfold((Some(first), 0usize), move |(pending, read)| async move {
            match pending {
                None => Ok(None),
                Some(page) => {
                    let read = read + 1;
                    let following = if read < max_pages {
                        self.next_page(&page).await?
                    } else {
                        None
                    };
                    Ok(Some((page, (following, read))))
                }
            }
        })
    }

    /// Every item on every page, read lazily as the stream is polled.
    pub fn items<'a, T: DeserializeOwned + 'a>(
        &'a self,
        first: Page<Vec<T>>,
    ) -> impl Stream<Item = Result<T, Error>> + 'a {
        self.pages(first).flat_map(|page| match page {
            Ok(page) => stream::iter(page.into_inner().into_iter().map(Ok)).left_stream(),
            Err(error) => stream::once(async move { Err(error) }).right_stream(),
        })
    }

    /// Reads a paginated path to its end and hands back the items of every page as one
    /// list. Each page has to decode as a JSON array. Use this for the paths the model
    /// does not cover; a modelled read walks with [`Client::each_page`] or
    /// [`Client::pages`], which keep the records typed.
    pub async fn get_all(&self, path: &str) -> Result<Vec<Value>, Error> {
        self.get_all_with_limit(path, 0).await
    }

    /// Reads a paginated path until `limit` items are in hand, or to its end when `limit`
    /// is zero. The last page is trimmed to land on exactly `limit`.
    pub async fn get_all_with_limit(&self, path: &str, limit: usize) -> Result<Vec<Value>, Error> {
        let operation = self.raw(Method::GET, path)?;
        self.collect_all(operation, limit).await
    }

    pub(crate) async fn collect_all(
        &self,
        mut operation: Operation,
        limit: usize,
    ) -> Result<Vec<Value>, Error> {
        let started_at = self.url_for(&operation)?;
        let retry = operation.retry.clone();
        let mut collected: Vec<Value> = Vec::new();
        let mut pages = 0;

        loop {
            let response = self.execute(operation).await?;
            collected.extend(response.json::<Vec<Value>>()?);
            pages += 1;

            if limit > 0 && collected.len() >= limit {
                collected.truncate(limit);
                break;
            }
            match self.next_page_url(&response, &started_at)? {
                Some(next) if pages < self.max_pages() => {
                    operation = Operation::at(Method::GET, next);
                    if let Some(retry) = &retry {
                        operation.retry(retry.clone());
                    }
                }
                Some(_) => {
                    crate::trace::warn(&format!("pagination capped at {} pages", self.max_pages()));
                    break;
                }
                None => break,
            }
        }
        Ok(collected)
    }

    /// The page after this one, as the `Link` header named it, resolved against the answer
    /// it came in. A target off the origin the walk started on is refused rather than
    /// followed: the header is the server's to write, and following it would carry the
    /// credentials somewhere they were never meant to go.
    fn next_page_url(&self, response: &Response, started_at: &Url) -> Result<Option<Url>, Error> {
        match response.header("link").and_then(next_link) {
            None => Ok(None),
            Some(target) => {
                let next = response.url.join(&target)?;
                if is_same_origin(&next, started_at) {
                    Ok(Some(next))
                } else {
                    Err(Error::usage(format!(
                        "pagination Link header points to a different origin: {next}"
                    )))
                }
            }
        }
    }
}

/// The target of the `rel="next"` link in an RFC 8288 `Link` header. Targets are read
/// between angle brackets, so commas inside a URL do not split it, and `rel` is a
/// space-separated set matched case-insensitively.
pub fn next_link(header: &str) -> Option<String> {
    let mut remaining = header;
    while let Some(start) = remaining.find('<') {
        let after_start = &remaining[start + 1..];
        let end = after_start.find('>')?;
        let target = &after_start[..end];
        let rest = &after_start[end + 1..];
        let params_end = rest.find('<').unwrap_or(rest.len());
        if link_is_next(&rest[..params_end]) {
            return Some(target.to_string());
        }
        remaining = &rest[params_end..];
    }
    None
}

fn link_is_next(params: &str) -> bool {
    params.split(';').any(|param| {
        let mut parts = param.splitn(2, '=');
        let name = parts.next().unwrap_or_default().trim();
        let value = parts.next().unwrap_or_default().trim().trim_matches('"');
        name.eq_ignore_ascii_case("rel")
            && value
                .split_whitespace()
                .any(|rel| rel.eq_ignore_ascii_case("next"))
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn finds_the_next_link_among_others() {
        let header = r#"<https://fizzy.do/999/boards.json?page=1>; rel="prev", <https://fizzy.do/999/boards.json?page=3>; rel="next""#;
        assert_eq!(
            next_link(header).as_deref(),
            Some("https://fizzy.do/999/boards.json?page=3")
        );
    }

    #[test]
    fn matches_rel_sets_and_case() {
        assert_eq!(
            next_link(r#"</x?page=2>; REL="prev next""#).as_deref(),
            Some("/x?page=2")
        );
        assert_eq!(next_link(r#"</x?page=2>; rel="last""#), None);
        assert_eq!(next_link(""), None);
    }
}
