// @generated from OpenAPI spec — do not edit directly
import Foundation

public final class PinsService: BaseService, @unchecked Sendable {
    public func list() async throws -> [Pin] {
        return try await request(
            OperationInfo(service: "Pins", operation: "ListPins", resourceType: "pin", isMutation: false),
            method: "GET",
            path: "/my/pins.json",
            retryConfig: Metadata.retryConfig(for: "ListPins")
        )
    }
}
