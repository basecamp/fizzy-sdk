// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct WebhookDeliveryEvent: Codable, Sendable {
    public let action: String
    public let createdAt: String
    public let id: String
    public var creator: WebhookDeliveryEventCreator?
    public var eventable: WebhookDeliveryEventEventable?

    public init(
        action: String,
        createdAt: String,
        id: String,
        creator: WebhookDeliveryEventCreator? = nil,
        eventable: WebhookDeliveryEventEventable? = nil
    ) {
        self.action = action
        self.createdAt = createdAt
        self.id = id
        self.creator = creator
        self.eventable = eventable
    }
}
