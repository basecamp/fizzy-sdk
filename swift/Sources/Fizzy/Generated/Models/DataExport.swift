// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct DataExport: Codable, Sendable {
    public let createdAt: String
    public let id: String
    public let status: String
    public var downloadUrl: String?

    public init(
        createdAt: String,
        id: String,
        status: String,
        downloadUrl: String? = nil
    ) {
        self.createdAt = createdAt
        self.id = id
        self.status = status
        self.downloadUrl = downloadUrl
    }
}
