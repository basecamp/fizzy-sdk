// @generated from OpenAPI spec — do not edit directly
import Foundation

public final class DevicesService: BaseService, @unchecked Sendable {
    public func register(accountId: String, req: RegisterDeviceRequest) async throws {
        try await requestVoid(
            OperationInfo(service: "Devices", operation: "RegisterDevice", resourceType: "device", isMutation: true),
            method: "POST",
            path: "/\(accountId)/devices",
            body: req,
            retryConfig: Metadata.retryConfig(for: "RegisterDevice")
        )
    }

    public func unregister(accountId: String, deviceToken: String) async throws {
        try await requestVoid(
            OperationInfo(service: "Devices", operation: "UnregisterDevice", resourceType: "device", isMutation: true),
            method: "DELETE",
            path: "/\(accountId)/devices/\(deviceToken)",
            retryConfig: Metadata.retryConfig(for: "UnregisterDevice")
        )
    }
}
