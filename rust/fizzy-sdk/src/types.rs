//! The scalar types the model speaks that Rust has no single spelling for.

use std::fmt;

use chrono::Utc;
use serde::{Deserialize, Serialize};

/// An instant Fizzy reports, always with its offset.
pub type DateTime = chrono::DateTime<Utc>;

/// Reads a required field that arrived as `null` as its type's default. Reach for it with
/// `#[serde(default, deserialize_with = "crate::types::null_as_default::deserialize")]`,
/// which the generator puts on every required field of a type that has a zero value.
///
/// Fizzy writes `null` where it has nothing for a field the model calls required, and Go's
/// `encoding/json` reads that into a non-pointer as a no-op — the field keeps its zero
/// value. `#[serde(default)]` alone only covers the field being absent, so without this a
/// `null` fails the whole response where Go reads it as `""` or `0`.
pub mod null_as_default {
    use serde::{Deserialize, Deserializer};

    /// Reads `null` as `T::default()`.
    pub fn deserialize<'de, D: Deserializer<'de>, T: Deserialize<'de> + Default>(
        deserializer: D,
    ) -> Result<T, D::Error> {
        Ok(Option::<T>::deserialize(deserializer)?.unwrap_or_default())
    }
}

/// A string that must not end up in logs: an email address, a person's name, a token. It
/// prints as `[REDACTED]`; call [`SensitiveString::expose`] to read it.
#[derive(Clone, PartialEq, Eq, Hash, Default, Serialize, Deserialize)]
#[serde(transparent)]
pub struct SensitiveString(String);

impl SensitiveString {
    /// Wraps a value.
    pub fn new(value: impl Into<String>) -> SensitiveString {
        SensitiveString(value.into())
    }

    /// The value itself.
    pub fn expose(&self) -> &str {
        &self.0
    }

    /// The value itself, owned.
    pub fn into_inner(self) -> String {
        self.0
    }

    /// Whether there is nothing to hide.
    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }
}

impl From<String> for SensitiveString {
    fn from(value: String) -> SensitiveString {
        SensitiveString(value)
    }
}

impl From<&str> for SensitiveString {
    fn from(value: &str) -> SensitiveString {
        SensitiveString(value.to_string())
    }
}

impl fmt::Debug for SensitiveString {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        if self.0.is_empty() {
            f.write_str("\"\"")
        } else {
            f.write_str("[REDACTED]")
        }
    }
}

impl fmt::Display for SensitiveString {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        if self.0.is_empty() {
            Ok(())
        } else {
            f.write_str("[REDACTED]")
        }
    }
}

#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests {
    use super::*;

    #[test]
    fn sensitive_strings_hide_their_value() {
        let secret = SensitiveString::new("jane@example.com");
        assert_eq!(format!("{secret:?}"), "[REDACTED]");
        assert_eq!(secret.to_string(), "[REDACTED]");
        assert_eq!(secret.expose(), "jane@example.com");
        assert_eq!(
            serde_json::to_string(&secret).unwrap(),
            "\"jane@example.com\""
        );
    }

    #[test]
    fn timestamps_read_with_any_offset() {
        let utc: DateTime = serde_json::from_str("\"2026-01-01T00:00:00Z\"").unwrap();
        let offset: DateTime = serde_json::from_str("\"2025-12-31T19:00:00-05:00\"").unwrap();
        assert_eq!(utc, offset);
    }
}
