// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct PendingAuthentication: Codable, Sendable {
    public let pendingAuthenticationToken: String

    public init(pendingAuthenticationToken: String) {
        self.pendingAuthenticationToken = pendingAuthenticationToken
    }
}
