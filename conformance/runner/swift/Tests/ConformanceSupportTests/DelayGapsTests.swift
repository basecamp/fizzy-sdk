import Testing

@testable import ConformanceSupport

/// Bounds and every-gap contract for the `delayBetweenRequests` assertion.
/// Each case names a way an evaluator can look like it covers a timing gap
/// and not: measuring only the first gap, or skipping the check entirely on a
/// single-request run.
@Suite("delayBetweenRequests gaps")
struct DelayGapsTests {
    /// Builds request timestamps from successive gaps in milliseconds.
    private func times(_ gapsMs: UInt64...) -> [UInt64] {
        var out: [UInt64] = [0]
        for ms in gapsMs { out.append(out[out.count - 1] + ms) }
        return out
    }

    @Test("A later failing gap is caught, not just gap 0")
    func laterGapFails() throws {
        let failure = try #require(checkDelayGaps(times(1000, 5), minDelayMs: 500))
        #expect(failure.contains("at gap 1"))
    }

    @Test("Every gap clearing the minimum passes")
    func everyGapPasses() {
        #expect(checkDelayGaps(times(1000, 2000, 800), minDelayMs: 500) == nil)
    }

    @Test("A single request has no gap to measure and fails")
    func singleRequestFails() {
        // An every-gap rule with no gaps left must not wave the run through:
        // a fully dropped retry lands exactly here.
        #expect(
            checkDelayGaps(times(), minDelayMs: 500)
                == "Expected a delay between requests, but only 1 request(s) were made")
    }

    @Test("No requests at all fails rather than reading out of bounds")
    func noRequestsFails() {
        #expect(
            checkDelayGaps([], minDelayMs: 500)
                == "Expected a delay between requests, but only 0 request(s) were made")
    }

    @Test("A zero or absent minimum still asserts the gap exists")
    func zeroMinimumStillRequiresAGap() {
        #expect(
            checkDelayGaps(times(), minDelayMs: 0)
                == "Expected a delay between requests, but only 1 request(s) were made")
        #expect(
            checkDelayGaps(times(), minDelayMs: nil)
                == "Expected a delay between requests, but only 1 request(s) were made")
        #expect(checkDelayGaps(times(5), minDelayMs: 0) == nil)
        #expect(checkDelayGaps(times(5), minDelayMs: nil) == nil)
    }

    @Test("A gap below the minimum names the gap and the shortfall")
    func shortfallIsNamed() {
        #expect(
            checkDelayGaps(times(5), minDelayMs: 1000)
                == "Expected delay >= 1000ms at gap 0, got 5ms")
    }

    @Test("A non-monotonic pair saturates to zero instead of trapping")
    func decreasingPairSaturates() throws {
        let failure = try #require(checkDelayGaps([1000, 900], minDelayMs: 1))
        #expect(failure.contains("got 0ms"))
    }
}
