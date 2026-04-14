// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct WebhookDeliveryEventEventable: Codable, Sendable {
    public let id: String
    public let type: String
    public let url: String

    public init(id: String, type: String, url: String) {
        self.id = id
        self.type = type
        self.url = url
    }
}
