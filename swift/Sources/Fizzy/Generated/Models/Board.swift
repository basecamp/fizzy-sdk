// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Board: Codable, Sendable {
    public let allAccess: Bool
    public let createdAt: String
    public let id: String
    public let name: String
    public let url: String
    public var autoPostponePeriodInDays: Int32?
    public var creator: User?
    public var publicDescription: String?
    public var publicDescriptionHtml: String?
    public var publicUrl: String?
    public var userIds: [String]?

    public init(
        allAccess: Bool,
        createdAt: String,
        id: String,
        name: String,
        url: String,
        autoPostponePeriodInDays: Int32? = nil,
        creator: User? = nil,
        publicDescription: String? = nil,
        publicDescriptionHtml: String? = nil,
        publicUrl: String? = nil,
        userIds: [String]? = nil
    ) {
        self.allAccess = allAccess
        self.createdAt = createdAt
        self.id = id
        self.name = name
        self.url = url
        self.autoPostponePeriodInDays = autoPostponePeriodInDays
        self.creator = creator
        self.publicDescription = publicDescription
        self.publicDescriptionHtml = publicDescriptionHtml
        self.publicUrl = publicUrl
        self.userIds = userIds
    }
}
