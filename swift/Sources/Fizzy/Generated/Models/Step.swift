// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Step: Codable, Sendable {
    public let completed: Bool
    public let content: String
    public let id: Int

    public init(completed: Bool, content: String, id: Int) {
        self.completed = completed
        self.content = content
        self.id = id
    }
}
