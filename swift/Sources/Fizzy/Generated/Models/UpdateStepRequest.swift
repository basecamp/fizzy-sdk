// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct UpdateStepRequest: Codable, Sendable {
    public var completed: Bool?
    public var content: String?

    public init(completed: Bool? = nil, content: String? = nil) {
        self.completed = completed
        self.content = content
    }
}
