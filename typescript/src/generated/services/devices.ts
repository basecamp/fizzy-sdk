/**
 * Devices service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import type { components } from "../schema.js";

export interface RegisterDeviceRequest {
  token: string;
  platform: string;
  /** Display name */
  name?: string;
}

export class DevicesService extends BaseService {

  /**
   * RegisterDevice
   */
  async register(body: RegisterDeviceRequest): Promise<void> {
    return this.request(
      {
        service: "Device",
        operation: "RegisterDevice",
        resourceType: "device",
        isMutation: true,
      },
      () => this.client.POST("/devices" as never, {
        body: { token: body.token, platform: body.platform, name: body.name } as never,
      } as never),
    );
  }

  /**
   * UnregisterDevice
   */
  async unregister(deviceToken: string): Promise<void> {
    return this.request(
      {
        service: "Device",
        operation: "UnregisterDevice",
        resourceType: "device",
        isMutation: true,
      },
      () => this.client.DELETE("/devices/{deviceToken}" as never, {
        params: { path: { deviceToken } },
      } as never),
    );
  }
}
