// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Step: Codable, Sendable {
    public let completed: Bool
    public let content: String
    public let id: String

    public init(completed: Bool, content: String, id: String) {
        self.completed = completed
        self.content = content
        self.id = id
    }
}
