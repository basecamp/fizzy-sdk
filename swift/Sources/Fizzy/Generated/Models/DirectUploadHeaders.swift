// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct DirectUploadHeaders: Codable, Sendable {
    public let contentType: String
    public var contentMd5: String?

    public init(contentType: String, contentMd5: String? = nil) {
        self.contentType = contentType
        self.contentMd5 = contentMd5
    }
}
