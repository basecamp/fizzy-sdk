// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct CreateDirectUploadRequest: Codable, Sendable {
    public let byteSize: Int
    public let checksum: String
    public let contentType: String
    public let filename: String

    public init(
        byteSize: Int,
        checksum: String,
        contentType: String,
        filename: String
    ) {
        self.byteSize = byteSize
        self.checksum = checksum
        self.contentType = contentType
        self.filename = filename
    }
}
