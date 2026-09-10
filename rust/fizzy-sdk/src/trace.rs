//! The crate's own log lines, on `tracing` when the feature is on and silent otherwise.

#[cfg(feature = "tracing")]
pub(crate) fn debug(operation: &str, attempt: u32, detail: &str) {
    tracing::debug!(operation, attempt, "{detail}");
}

#[cfg(not(feature = "tracing"))]
pub(crate) fn debug(_operation: &str, _attempt: u32, _detail: &str) {}

#[cfg(feature = "tracing")]
pub(crate) fn warn(detail: &str) {
    tracing::warn!("{detail}");
}

#[cfg(not(feature = "tracing"))]
pub(crate) fn warn(_detail: &str) {}
