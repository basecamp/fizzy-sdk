/// How `configOverrides.maxRetries` reaches a Swift client.
///
/// The key is a TOTAL attempt count, and the Swift SDK exposes no numeric cap
/// by design: its loop is driven by each operation's generated `retry.max`
/// ceiling and floored at one attempt (`max(enableRetry ? maxAttempts : 1, 1)`
/// in `HTTPClient`), with `enableRetry` as the only client-wide knob. So the
/// cap maps onto that knob, the same way the TypeScript runner spells it.
///
/// The cutoff is `> 1`, not `> 0`: 0 and 1 both mean exactly one attempt, and
/// one attempt is what `enableRetry: false` spells here. Mapping 1 to enabled
/// would hand this runner the per-operation ceiling of 2–3 attempts while the
/// numeric SDKs made exactly one. A cap above 1 only re-asserts the default
/// policy; it cannot pin an exact attempt count in Swift, and the fixture
/// schema says so.
///
/// An absent key leaves the SDK default (retries on) in place.
public func retryEnabled(forMaxRetries cap: Int?) -> Bool {
    cap.map { $0 > 1 } ?? true
}
