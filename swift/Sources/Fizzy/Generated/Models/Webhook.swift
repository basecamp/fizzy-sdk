// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Webhook: Codable, Sendable {
    public let active: Bool
    public let createdAt: String
    public let id: String
    public let name: String
    public let signingSecret: String
    public let subscribedActions: [String]
    public let updatedAt: String
    public let url: String

    public init(
        active: Bool,
        createdAt: String,
        id: String,
        name: String,
        signingSecret: String,
        subscribedActions: [String],
        updatedAt: String,
        url: String
    ) {
        self.active = active
        self.createdAt = createdAt
        self.id = id
        self.name = name
        self.signingSecret = signingSecret
        self.subscribedActions = subscribedActions
        self.updatedAt = updatedAt
        self.url = url
    }
}
