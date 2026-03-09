// @generated from OpenAPI spec — do not edit directly
import Foundation

public struct UpdateBoardEntropyRequest: Codable, Sendable {
    public var autoPostponePeriod: Int32?

    public init(autoPostponePeriod: Int32? = nil) {
        self.autoPostponePeriod = autoPostponePeriod
    }
}
