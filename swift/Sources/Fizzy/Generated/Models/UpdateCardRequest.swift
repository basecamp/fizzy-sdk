// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct UpdateCardRequest: Codable, Sendable {
    public var columnId: Int?
    public var description: String?
    public var title: String?

    public init(columnId: Int? = nil, description: String? = nil, title: String? = nil) {
        self.columnId = columnId
        self.description = description
        self.title = title
    }
}
