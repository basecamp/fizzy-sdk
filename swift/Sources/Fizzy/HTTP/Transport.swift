import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Abstraction over URL loading for testability.
///
/// Production code uses `URLSessionTransport`; tests use `MockTransport`.
public protocol Transport: Sendable {
    /// Loads data for the given request.
    ///
    /// - Parameter request: The URL request to execute.
    /// - Returns: A tuple of the response data and URL response.
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Production transport that delegates to `URLSession`.
public struct URLSessionTransport: Transport, Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
