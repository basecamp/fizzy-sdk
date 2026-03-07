// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct CreateCommentRequest: Codable, Sendable {
    public let body: String
    public var createdAt: String?

    public init(body: String, createdAt: String? = nil) {
        self.body = body
        self.createdAt = createdAt
    }
}
