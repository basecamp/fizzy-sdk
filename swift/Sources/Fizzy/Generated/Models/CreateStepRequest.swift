// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct CreateStepRequest: Codable, Sendable {
    public var completed: Bool?
    public let content: String

    public init(completed: Bool? = nil, content: String) {
        self.completed = completed
        self.content = content
    }
}
