/**
 * Notifications service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export type Notification = components["schemas"]["Notification"];
export type NotificationTray = components["schemas"]["NotificationTray"];

export class NotificationsService extends BaseService {

  async list(options?: PaginationOptions): Promise<ListResult<Notification>> {
    return this.requestPaginated(
      { service: "Notifications", operation: "List", resourceType: "notification", isMutation: false },
      () => this.client.GET("/notifications.json" as never, {} as never),
      options,
    );
  }

  async read(notificationId: number): Promise<void> {
    return this.request(
      { service: "Notifications", operation: "Read", resourceType: "notification", isMutation: true, resourceId: notificationId },
      () => this.client.PUT("/notifications/{notificationId}/read.json" as never, {
        params: { path: { notificationId } },
      } as never),
    );
  }

  async unread(notificationId: number): Promise<void> {
    return this.request(
      { service: "Notifications", operation: "Unread", resourceType: "notification", isMutation: true, resourceId: notificationId },
      () => this.client.PUT("/notifications/{notificationId}/unread.json" as never, {
        params: { path: { notificationId } },
      } as never),
    );
  }

  async bulkRead(): Promise<void> {
    return this.request(
      { service: "Notifications", operation: "BulkRead", resourceType: "notification", isMutation: true },
      () => this.client.PUT("/notifications/read.json" as never, {} as never),
    );
  }

  async tray(): Promise<NotificationTray> {
    return this.request(
      { service: "Notifications", operation: "Tray", resourceType: "notification_tray", isMutation: false },
      () => this.client.GET("/notifications/tray.json" as never, {} as never),
    );
  }
}
