// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct RequestEmailAddressChangeRequest: Codable, Sendable {
    public let emailAddress: String

    public init(emailAddress: String) {
        self.emailAddress = emailAddress
    }
}
