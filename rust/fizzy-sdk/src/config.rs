//! What a client is configured with, and where it reads that from.

use std::env;
use std::path::PathBuf;

use serde::{Deserialize, Serialize};

/// Where a client sends when nothing says otherwise.
pub const DEFAULT_BASE_URL: &str = "https://fizzy.do";

/// What a client needs to know before it can talk to Fizzy.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(default)]
#[non_exhaustive]
pub struct Config {
    /// The API origin: `https://fizzy.do`, or a Fizzy running on this machine.
    pub base_url: String,
    /// The account most calls are scoped to, when there is a usual one.
    pub account: Option<String>,
    /// Where the response cache keeps its files.
    pub cache_dir: PathBuf,
    /// Whether reads are cached by `ETag`.
    pub cache_enabled: bool,
}

impl Default for Config {
    fn default() -> Config {
        Config {
            base_url: DEFAULT_BASE_URL.to_string(),
            account: None,
            cache_dir: default_cache_dir(),
            cache_enabled: false,
        }
    }
}

impl Config {
    /// The defaults.
    pub fn new() -> Config {
        Config::default()
    }

    /// Lets `FIZZY_API_URL`, `FIZZY_ACCOUNT`, `FIZZY_CACHE_DIR` and `FIZZY_CACHE_ENABLED`
    /// override whatever is set, the same variables the Go SDK reads. An empty variable
    /// counts as unset.
    pub fn with_env(mut self) -> Config {
        if let Some(value) = env_value("FIZZY_API_URL") {
            self.base_url = value;
        }
        if let Some(value) = env_value("FIZZY_ACCOUNT") {
            self.account = Some(value);
        }
        if let Some(value) = env_value("FIZZY_CACHE_DIR") {
            self.cache_dir = PathBuf::from(value);
        }
        if let Some(value) = env_value("FIZZY_CACHE_ENABLED") {
            self.cache_enabled = value.eq_ignore_ascii_case("true") || value == "1";
        }
        self
    }

    /// Points the client somewhere other than `https://fizzy.do`.
    pub fn with_base_url(mut self, base_url: impl Into<String>) -> Config {
        self.base_url = base_url.into();
        self
    }

    /// Names the usual account.
    pub fn with_account(mut self, account: impl Into<String>) -> Config {
        self.account = Some(account.into());
        self
    }

    /// Turns the `ETag` cache on or off.
    pub fn with_cache_enabled(mut self, enabled: bool) -> Config {
        self.cache_enabled = enabled;
        self
    }

    /// Moves the cache directory.
    pub fn with_cache_dir(mut self, cache_dir: impl Into<PathBuf>) -> Config {
        self.cache_dir = cache_dir.into();
        self
    }

    /// The base URL without a trailing slash.
    pub fn origin(&self) -> &str {
        self.base_url.trim_end_matches('/')
    }
}

fn env_value(name: &str) -> Option<String> {
    env::var(name).ok().filter(|value| !value.is_empty())
}

/// Where the response cache goes when nothing says otherwise: `$XDG_CACHE_HOME/fizzy`,
/// falling back to `~/.cache/fizzy`.
pub fn default_cache_dir() -> PathBuf {
    xdg_dir("XDG_CACHE_HOME", ".cache").join("fizzy")
}

/// Where credentials and settings go when nothing says otherwise: `$XDG_CONFIG_HOME/fizzy`,
/// falling back to `~/.config/fizzy`. Shared with the Fizzy CLI.
pub fn default_config_dir() -> PathBuf {
    xdg_dir("XDG_CONFIG_HOME", ".config").join("fizzy")
}

fn xdg_dir(variable: &str, fallback: &str) -> PathBuf {
    match env_value(variable) {
        Some(value) => PathBuf::from(value),
        None => env::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join(fallback),
    }
}
