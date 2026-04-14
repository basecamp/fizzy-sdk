// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Identity: Codable, Sendable {
    public let accounts: [Account]
    public let id: String
    public var emailAddress: String?
    public var name: String?

    public init(
        accounts: [Account],
        id: String,
        emailAddress: String? = nil,
        name: String? = nil
    ) {
        self.accounts = accounts
        self.id = id
        self.emailAddress = emailAddress
        self.name = name
    }
}
