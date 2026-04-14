// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct WebhookDelivery: Codable, Sendable {
    public let createdAt: String
    public let id: String
    public let state: String
    public let updatedAt: String
    public var event: WebhookDeliveryEvent?
    public var request: WebhookDeliveryRequest?
    public var response: WebhookDeliveryResponse?

    public init(
        createdAt: String,
        id: String,
        state: String,
        updatedAt: String,
        event: WebhookDeliveryEvent? = nil,
        request: WebhookDeliveryRequest? = nil,
        response: WebhookDeliveryResponse? = nil
    ) {
        self.createdAt = createdAt
        self.id = id
        self.state = state
        self.updatedAt = updatedAt
        self.event = event
        self.request = request
        self.response = response
    }
}
