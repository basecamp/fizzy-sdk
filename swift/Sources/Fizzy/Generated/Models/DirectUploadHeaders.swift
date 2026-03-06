// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct DirectUploadHeaders: Codable, Sendable {
    public let ContentType: String
    public var ContentMD5: String?

    public init(ContentType: String, ContentMD5: String? = nil) {
        self.ContentType = ContentType
        self.ContentMD5 = ContentMD5
    }
}
