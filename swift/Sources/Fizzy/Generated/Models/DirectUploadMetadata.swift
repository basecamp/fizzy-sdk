// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct DirectUploadMetadata: Codable, Sendable {
    public let headers: DirectUploadHeaders
    public let url: String

    public init(headers: DirectUploadHeaders, url: String) {
        self.headers = headers
        self.url = url
    }
}
