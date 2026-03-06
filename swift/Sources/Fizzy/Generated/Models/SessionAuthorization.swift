// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct SessionAuthorization: Codable, Sendable {
    public let requiresSignupCompletion: Bool
    public let sessionToken: String

    public init(requiresSignupCompletion: Bool, sessionToken: String) {
        self.requiresSignupCompletion = requiresSignupCompletion
        self.sessionToken = sessionToken
    }
}
