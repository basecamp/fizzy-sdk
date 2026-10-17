// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct UpdateWebhookRequest: Codable, Sendable {
    public var name: String?
    public var subscribedActions: [String]?

    public init(name: String? = nil, subscribedActions: [String]? = nil) {
        self.name = name
        self.subscribedActions = subscribedActions
    }
}
