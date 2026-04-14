// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Webhook: Codable, Sendable {
    public let active: Bool
    public let createdAt: String
    public let id: String
    public let name: String
    public let payloadUrl: String
    public let signingSecret: String
    public let subscribedActions: [String]
    public let url: String
    public var board: Board?
    public var updatedAt: String?

    public init(
        active: Bool,
        createdAt: String,
        id: String,
        name: String,
        payloadUrl: String,
        signingSecret: String,
        subscribedActions: [String],
        url: String,
        board: Board? = nil,
        updatedAt: String? = nil
    ) {
        self.active = active
        self.createdAt = createdAt
        self.id = id
        self.name = name
        self.payloadUrl = payloadUrl
        self.signingSecret = signingSecret
        self.subscribedActions = subscribedActions
        self.url = url
        self.board = board
        self.updatedAt = updatedAt
    }
}
