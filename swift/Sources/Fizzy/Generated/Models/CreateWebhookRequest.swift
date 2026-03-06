// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct CreateWebhookRequest: Codable, Sendable {
    public let name: String
    public var subscribedActions: [String]?
    public let url: String

    public init(name: String, subscribedActions: [String]? = nil, url: String) {
        self.name = name
        self.subscribedActions = subscribedActions
        self.url = url
    }
}
