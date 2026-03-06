// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct Identity: Codable, Sendable {
    public let accounts: [Account]
    public let emailAddress: String
    public let id: Int
    public let name: String

    public init(
        accounts: [Account],
        emailAddress: String,
        id: Int,
        name: String
    ) {
        self.accounts = accounts
        self.emailAddress = emailAddress
        self.id = id
        self.name = name
    }
}
