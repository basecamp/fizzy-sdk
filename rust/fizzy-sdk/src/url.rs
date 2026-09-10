//! Recognizing pasted Fizzy URLs offline.

use std::collections::BTreeMap;
use std::sync::OnceLock;

use url::Url;

use crate::generated::routes::ROUTES;
use crate::http::Method;
use crate::route::Route;

/// Recognizes Fizzy paths and URLs, as pasted from the web app, and names the operation,
/// resource and ids they refer to. Works offline.
pub struct Router {
    patterns: Vec<Pattern>,
}

struct Pattern {
    pattern: &'static str,
    routes: Vec<&'static Route>,
}

/// What a recognized path refers to.
#[derive(Debug, Clone, PartialEq, Eq)]
#[non_exhaustive]
pub struct Match {
    /// The route pattern that matched.
    pub pattern: &'static str,
    /// The kind of record the path names.
    pub resource_type: &'static str,
    /// The operations served on this path, by method.
    pub operations: BTreeMap<String, &'static str>,
    /// The path parameters in the order they appear, the account first.
    pub params: Vec<(&'static str, String)>,
}

impl Match {
    /// The read on this path, or the alphabetically first operation when there is none.
    pub fn operation(&self) -> Option<&'static str> {
        self.operations
            .get(Method::GET.as_str())
            .or_else(|| self.operations.values().min())
            .copied()
    }

    /// The account the path is under, when it is under one.
    pub fn account_id(&self) -> Option<&str> {
        self.params
            .iter()
            .find(|(name, _)| *name == "accountId")
            .map(|(_, value)| value.as_str())
    }

    /// The last path parameter: the id of the record the path names, if any.
    pub fn resource_id(&self) -> Option<&str> {
        self.params
            .last()
            .filter(|(name, _)| *name != "accountId")
            .map(|(_, value)| value.as_str())
    }
}

impl Router {
    /// A router over every modelled route.
    pub fn new() -> Router {
        Router::over(ROUTES)
    }

    /// A router over a chosen set of routes, for a caller that recognizes only part of
    /// Fizzy — one service's paths, say.
    pub fn over(routes: &[&'static Route]) -> Router {
        let mut by_pattern: BTreeMap<&'static str, Vec<&'static Route>> = BTreeMap::new();
        for route in routes {
            by_pattern.entry(route.pattern).or_default().push(route);
        }
        let mut patterns: Vec<Pattern> = by_pattern
            .into_iter()
            .map(|(pattern, routes)| Pattern { pattern, routes })
            .collect();
        patterns.sort_by(|a, b| {
            let literals =
                |pattern: &str| pattern.split('/').filter(|s| !s.starts_with('{')).count();
            let depth = |pattern: &str| pattern.matches('/').count();
            depth(b.pattern)
                .cmp(&depth(a.pattern))
                .then_with(|| literals(b.pattern).cmp(&literals(a.pattern)))
                .then_with(|| a.pattern.cmp(b.pattern))
        });
        Router { patterns }
    }

    /// Recognizes a path such as `/999/boards/abc` or a full URL such as
    /// `https://fizzy.do/999/cards/12.json?x=1`. Trailing slashes, a `.json` suffix, the
    /// query and the fragment are ignored.
    pub fn recognize(&self, path_or_url: &str) -> Option<Match> {
        let path = match Url::parse(path_or_url) {
            Ok(url) if !url.cannot_be_a_base() => url.path().to_string(),
            _ => path_or_url
                .split(['?', '#'])
                .next()
                .unwrap_or_default()
                .to_string(),
        };
        let path = path.trim_end_matches('/');
        let path = path.strip_suffix(".json").unwrap_or(path);
        self.patterns
            .iter()
            .find_map(|pattern| pattern.recognize(path))
    }
}

impl Default for Router {
    fn default() -> Router {
        Router::new()
    }
}

impl Pattern {
    fn recognize(&self, path: &str) -> Option<Match> {
        let params = self.routes[0].recognize(path)?;
        let operations = self
            .routes
            .iter()
            .map(|route| (route.method.to_string(), route.id))
            .collect();
        Some(Match {
            pattern: self.pattern,
            resource_type: self.routes[0].resource_type,
            operations,
            params,
        })
    }
}

/// The process-wide router.
pub fn router() -> &'static Router {
    static ROUTER: OnceLock<Router> = OnceLock::new();
    ROUTER.get_or_init(Router::new)
}

#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests {
    use super::*;

    #[test]
    fn recognizes_a_pasted_card_url() {
        let matched = router()
            .recognize("https://fizzy.do/999/cards/42?x=1")
            .unwrap();
        assert_eq!(matched.operation(), Some("GetCard"));
        assert_eq!(matched.resource_type, "card");
        assert_eq!(matched.account_id(), Some("999"));
        assert_eq!(matched.resource_id(), Some("42"));
    }

    #[test]
    fn captured_parameters_come_back_decoded() {
        let matched = router().recognize("/999/cards/a%3Ab").unwrap();
        assert_eq!(matched.resource_id(), Some("a:b"));
    }

    #[test]
    fn literal_segments_win_over_parameters_at_the_same_depth() {
        let closed = router()
            .recognize("/999/boards/b1/columns/closed.json")
            .unwrap();
        assert_eq!(closed.operation(), Some("ListClosedCards"));
        let column = router().recognize("/999/boards/b1/columns/c9").unwrap();
        assert_eq!(column.operation(), Some("GetColumn"));
        assert_eq!(column.operations["DELETE"], "DeleteColumn");
        assert_eq!(
            column.params,
            vec![
                ("accountId", "999".to_string()),
                ("boardId", "b1".to_string()),
                ("columnId", "c9".to_string())
            ]
        );
    }

    #[test]
    fn account_free_paths_and_unknown_paths() {
        assert_eq!(
            router().recognize("/my/identity").unwrap().operation(),
            Some("GetMyIdentity")
        );
        assert_eq!(
            router().recognize("/session").unwrap().operation(),
            Some("CreateSession")
        );
        assert!(router().recognize("/nothing/here/at/all/really").is_none());
        assert!(router().recognize("/999//cards").is_none());
    }

    #[test]
    fn a_router_over_a_chosen_set_recognizes_only_those() {
        let router = Router::over(&[&crate::generated::routes::GET_BOARD]);
        assert_eq!(
            router.recognize("/999/boards/b1").unwrap().operation(),
            Some("GetBoard")
        );
        assert!(router.recognize("/999/cards/1").is_none());
    }
}
