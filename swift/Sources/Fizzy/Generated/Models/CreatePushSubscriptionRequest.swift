// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct CreatePushSubscriptionRequest: Codable, Sendable {
    public let authKey: String
    public let endpoint: String
    public let p256dhKey: String

    public init(authKey: String, endpoint: String, p256dhKey: String) {
        self.authKey = authKey
        self.endpoint = endpoint
        self.p256dhKey = p256dhKey
    }
}
