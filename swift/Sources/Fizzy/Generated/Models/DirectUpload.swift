// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct DirectUpload: Codable, Sendable {
    public let byteSize: Int
    public let checksum: String
    public let contentType: String
    public let directUpload: DirectUploadMetadata
    public let filename: String
    public let id: String
    public let key: String

    public init(
        byteSize: Int,
        checksum: String,
        contentType: String,
        directUpload: DirectUploadMetadata,
        filename: String,
        id: String,
        key: String
    ) {
        self.byteSize = byteSize
        self.checksum = checksum
        self.contentType = contentType
        self.directUpload = directUpload
        self.filename = filename
        self.id = id
        self.key = key
    }
}
