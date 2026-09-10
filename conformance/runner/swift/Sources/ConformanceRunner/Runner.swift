import ConformanceSupport
import Fizzy
import Foundation

private let testToken = "test-token"
private let runnerUserAgent = "fizzy-conformance-runner/1.0"

@main
struct Runner {
    static func main() async {
        // Child-process mode for the HTTPS-enforcement probe: constructing a
        // client with a non-HTTPS, non-localhost base URL must trap
        // (preconditionFailure), which only a subprocess can observe. Exit 0
        // means construction survived — the parent treats that as a failure.
        if CommandLine.arguments.count >= 3, CommandLine.arguments[1] == "--https-probe" {
            _ = FizzyClient(
                tokenProvider: StaticTokenProvider(testToken),
                userAgent: runnerUserAgent,
                config: FizzyConfig(baseURL: CommandLine.arguments[2]),
                transport: ScriptedTransport(responses: [])
            )
            exit(0)
        }

        let testsDir = URL(
            fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "../../tests",
            isDirectory: true)

        let files: [URL]
        do {
            files = try FileManager.default
                .contentsOfDirectory(at: testsDir, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
        } catch {
            FileHandle.standardError.write(Data("Error finding test files in \(testsDir.path): \(error)\n".utf8))
            exit(1)
        }
        if files.isEmpty {
            FileHandle.standardError.write(Data("No test files found in \(testsDir.path)\n".utf8))
            exit(1)
        }

        var passed = 0
        var failed = 0

        for file in files {
            // A file the runner cannot read or parse is a failure, not a file
            // with no cases in it: skipping it quietly would let a broken
            // fixture pass the gate. So is a file with no cases at all.
            let testCases: [TestCase]
            do {
                testCases = try JSONDecoder().decode([TestCase].self, from: Data(contentsOf: file))
            } catch {
                print("\n=== \(file.lastPathComponent) ===\n  FAIL  could not decode fixture file: \(error)")
                failed += 1
                continue
            }
            if testCases.isEmpty {
                print("\n=== \(file.lastPathComponent) ===\n  FAIL  the file contains no cases")
                failed += 1
                continue
            }
            print("\n=== \(file.lastPathComponent) (\(testCases.count) tests) ===")

            for tc in testCases {
                let result = await runTest(tc)
                if result.passed {
                    passed += 1
                    print("  PASS  \(tc.name)")
                } else {
                    failed += 1
                    print("  FAIL  \(tc.name)\n        \(result.message)")
                }
            }
        }

        print("\n\(passed) passed, \(failed) failed, \(passed + failed) total")
        exit(failed > 0 ? 1 : 0)
    }

    static func runTest(_ tc: TestCase) async -> TestResult {
        // Backstops for fixture shapes that would otherwise produce a PASS
        // while testing nothing. The schema gate is the authoritative check,
        // but a runner that reports green on a fixture it cannot honor is the
        // failure mode this suite exists to remove, so it fails loudly here too.
        if tc.assertions.isEmpty {
            return .fail("test case declares no assertions — it would pass without verifying anything")
        }
        if !tc.declaresMockResponses {
            return .fail("test case is missing mockResponses (an empty queue must be stated explicitly)")
        }
        for (i, mock) in tc.responses.enumerated() where mock.status == nil {
            return .fail("mockResponses[\(i)] has no status")
        }
        if let cap = tc.configOverrides?.maxRetries, cap < 0 {
            return .fail("configOverrides.maxRetries must not be negative, got \(cap)")
        }
        // maxItems reaches the SDK only through the per-operation options of
        // the paginating arms. Any other operation would run without the cap
        // while the fixture believed it had one, so the request-count
        // assertion would be measuring something else entirely.
        if tc.configOverrides?.maxItems != nil, !operationsHonoringMaxItems.contains(tc.operation) {
            return .fail("configOverrides.maxItems is set but \(tc.operation) does not paginate — the cap would be ignored")
        }

        let transport = ScriptedTransport(responses: tc.responses)
        // The SDK's own default when the fixture sets none: the fixtures write
        // their Link headers against it, so same-origin links stay same-origin
        // without any rewriting, and the transport never dials anyway.
        let baseURL = tc.configOverrides?.baseUrl ?? FizzyConfig.defaultBaseURL

        var caughtError: FizzyError?
        var httpStatus: Int?
        var dispatch = DispatchResult()

        if requiresHTTPSCrashProbe(baseURL) {
            // The SDK enforces HTTPS with preconditionFailure — a trap, not a
            // thrown error — so it can only be observed from outside the
            // process. The probe re-runs this binary in --https-probe mode and
            // expects the child to die; a surviving child means enforcement
            // did not fire.
            switch runHTTPSProbe(baseURL) {
            case .enforced:
                caughtError = .usage(message: "Base URL must use HTTPS: \(baseURL)", hint: nil)
            case .constructionSucceeded:
                return .fail("client construction with non-HTTPS base URL unexpectedly succeeded")
            case .probeFailure(let message):
                return .fail("HTTPS probe failed to run: \(message)")
            }
        } else {
            let client = FizzyClient(
                tokenProvider: StaticTokenProvider(testToken),
                userAgent: runnerUserAgent,
                config: FizzyConfig(
                    baseURL: baseURL,
                    enableRetry: retryEnabled(forMaxRetries: tc.configOverrides?.maxRetries),
                    maxPages: tc.configOverrides?.maxPages ?? 10_000
                ),
                transport: transport
            )

            do {
                dispatch = try await dispatchOperation(tc, client)
                httpStatus = transport.lastConsumedIndex.flatMap { tc.responses[$0].status }
            } catch let error as FizzyError {
                caughtError = error
                httpStatus = error.httpStatusCode
            } catch let error as RunnerError {
                // A fixture the dispatch table cannot honor as written: an
                // unknown operation, or a parameter that would have been
                // coerced into a call against the wrong resource. Both are
                // fixture bugs to fix, not runner limitations to skip.
                return .fail(error.description)
            } catch let error as DecodingError {
                // A mock body that fails the model's required-field validation
                // is a fixture bug, not a runner limitation: fail loudly so it
                // gets fixed instead of silently degrading coverage.
                return .fail("Mock body lacks required Swift model fields: \(describeDecodingError(error))")
            } catch {
                return .fail("Unexpected exception: \(type(of: error)): \(error)")
            }
        }

        return evaluateAssertions(
            tc,
            transport: transport,
            caughtError: caughtError,
            httpStatus: httpStatus,
            dispatch: dispatch
        )
    }
}

// MARK: - HTTPS enforcement probe

private enum HTTPSProbeOutcome {
    case enforced
    case constructionSucceeded
    case probeFailure(String)
}

/// Mirrors the SDK's carve-out (`HTTPClient.requireSecureTransport`: https,
/// or http to localhost / 127.0.0.1 / ::1) just to ROUTE the test: carved-out
/// URLs are safe to construct in-process; everything else must go through
/// the crash probe. The probe itself exercises the SDK's real enforcement, so
/// a routing mistake here surfaces as a loud failure, never a silent pass.
///
/// Every parsed non-HTTPS scheme outside the carve-out routes to the probe,
/// not just `http`: a fixture with `ftp://` would otherwise trap in-process
/// and take the whole run down with it.
private func requiresHTTPSCrashProbe(_ baseURL: String) -> Bool {
    // An unparseable URL never reaches the scheme check in the SDK either: the
    // guard is `if let url = URL(string:)`, so construction survives.
    guard let url = URL(string: baseURL) else { return false }
    let scheme = url.scheme?.lowercased()
    if scheme == "https" { return false }
    guard scheme == "http", let host = url.host?.lowercased() else { return true }
    return !(host == "localhost" || host == "127.0.0.1" || host == "::1")
}

private func runHTTPSProbe(_ baseURL: String) -> HTTPSProbeOutcome {
    let probe = Process()
    probe.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
    probe.arguments = ["--https-probe", baseURL]
    probe.standardError = Pipe()  // suppress the expected crash banner
    probe.standardOutput = Pipe()
    do {
        try probe.run()
        probe.waitUntilExit()
    } catch {
        return .probeFailure("\(error)")
    }
    let crashed = probe.terminationReason == .uncaughtSignal || probe.terminationStatus != 0
    return crashed ? .enforced : .constructionSucceeded
}

// MARK: - Decoding-error rendering

/// Renders a DecodingError with the missing key and coding path, which is the
/// actionable part when a fixture body under-specifies a model.
private func describeDecodingError(_ error: DecodingError) -> String {
    func renderPath(_ path: [any CodingKey]) -> String {
        path.map(\.stringValue).joined(separator: ".")
    }
    switch error {
    case .keyNotFound(let key, let context):
        return "missing key \"\(key.stringValue)\" at \(renderPath(context.codingPath))"
    case .typeMismatch(let type, let context):
        return "type mismatch (expected \(type)) at \(renderPath(context.codingPath)): \(context.debugDescription)"
    case .valueNotFound(let type, let context):
        return "null for non-optional \(type) at \(renderPath(context.codingPath))"
    case .dataCorrupted(let context):
        return "corrupted data at \(renderPath(context.codingPath)): \(context.debugDescription)"
    @unknown default:
        return "\(error)"
    }
}
