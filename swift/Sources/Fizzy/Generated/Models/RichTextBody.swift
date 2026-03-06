// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct RichTextBody: Codable, Sendable {
    public let html: String
    public let plainText: String

    public init(html: String, plainText: String) {
        self.html = html
        self.plainText = plainText
    }
}
