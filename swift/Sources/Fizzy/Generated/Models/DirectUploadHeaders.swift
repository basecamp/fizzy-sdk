// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct DirectUploadHeaders: Codable, Sendable {
    public let contentType: String
    public var contentMD5: String?

    public init(contentType: String, contentMD5: String? = nil) {
        self.contentType = contentType
        self.contentMD5 = contentMD5
    }
}
