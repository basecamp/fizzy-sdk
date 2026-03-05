/**
 * Devices service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import type { components } from "../schema.js";

export type Device = components["schemas"]["Device"];

export interface RegisterDeviceRequest {
  /** Push notification token */
  token: string;
  /** Device platform (ios, android, web) */
  platform: string;
}

export class DevicesService extends BaseService {

  async register(body: RegisterDeviceRequest): Promise<Device> {
    return this.request(
      { service: "Devices", operation: "Register", resourceType: "device", isMutation: true },
      () => this.client.POST("/devices.json" as never, {
        body: { token: body.token, platform: body.platform } as never,
      } as never),
    );
  }

  async unregister(deviceId: number): Promise<void> {
    return this.request(
      { service: "Devices", operation: "Unregister", resourceType: "device", isMutation: true, resourceId: deviceId },
      () => this.client.DELETE("/devices/{deviceId}.json" as never, {
        params: { path: { deviceId } },
      } as never),
    );
  }
}
