/// The `delayBetweenRequests` assertion contract, kept in its own SDK-free
/// target so its bounds branches are unit-tested: they never execute against a
/// fixture that passes, which is exactly how a vacuous version survives a
/// green run.

/// Validates the assertion against the recorded request times, returning `nil`
/// when it holds and a failure message otherwise.
///
/// Gap i is the interval between request i and request i+1, so N requests
/// yield N-1 gaps, and the minimum applies to EVERY gap. Zero gaps means
/// nothing was measured, so that fails too: an every-gap rule with no gaps
/// left would otherwise wave through a run that dropped every retry — the
/// whole point of a timing pin is to catch a dropped backoff, and a dropped
/// backoff is precisely what removes the gap.
public func checkDelayGaps(_ requestTimes: [UInt64], minDelayMs: Double?) -> String? {
    // An absent or zero minimum still asserts that the gap EXISTS. The default
    // lands here rather than at the call site so a truthiness gate cannot
    // quietly reduce the assertion to nothing.
    let minimum = minDelayMs ?? 0
    let gaps = requestTimes.count - 1

    if gaps < 1 {
        return "Expected a delay between requests, but only \(requestTimes.count) request(s) were made"
    }
    for gap in 0..<gaps {
        // Saturating rather than wrapping: the capture clock is monotonic, so
        // a decreasing pair cannot happen, and if it ever did a 0ms gap fails
        // a positive minimum — the fail-closed direction. Unsigned
        // subtraction traps on underflow, which would crash the runner.
        let later = requestTimes[gap + 1]
        let earlier = requestTimes[gap]
        let delay = later >= earlier ? later - earlier : 0
        if Double(delay) < minimum {
            return "Expected delay >= \(formatMs(minimum))ms at gap \(gap), got \(delay)ms"
        }
    }
    return nil
}

/// Renders an integral minimum without a trailing `.0`: every fixture states
/// whole milliseconds and "1000ms" reads better than "1000.0ms".
private func formatMs(_ value: Double) -> String {
    value == value.rounded() && value.magnitude < 1e15 ? String(Int64(value)) : String(value)
}
