import Testing

@testable import ConformanceSupport

/// The `configOverrides.maxRetries` mapping. Swift has no numeric cap, so the
/// whole override collapses onto `enableRetry`; these pin which side of the
/// knob each cap lands on, because the one-attempt floor case in retry.json
/// only observes a single point of it.
@Suite("maxRetries to enableRetry")
struct RetryCapTests {
    @Test("An absent cap keeps the SDK default of retrying")
    func absentKeepsDefault() {
        #expect(retryEnabled(forMaxRetries: nil) == true)
    }

    @Test("Zero and one both mean exactly one attempt")
    func zeroAndOneDisable() {
        // 0 is the value the key exists for; 1 is the same contract spelled
        // as a total attempt count. Mapping 1 to enabled would hand Swift the
        // per-operation ceiling while the numeric SDKs made one attempt.
        #expect(retryEnabled(forMaxRetries: 0) == false)
        #expect(retryEnabled(forMaxRetries: 1) == false)
    }

    @Test("A cap above one re-asserts the default policy")
    func aboveOneEnables() {
        #expect(retryEnabled(forMaxRetries: 2) == true)
        #expect(retryEnabled(forMaxRetries: 3) == true)
    }
}
