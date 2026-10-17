// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct UpdateAccountEntropyRequest: Codable, Sendable {
    public let autoPostponePeriodInDays: Int32

    public init(autoPostponePeriodInDays: Int32) {
        self.autoPostponePeriodInDays = autoPostponePeriodInDays
    }
}
