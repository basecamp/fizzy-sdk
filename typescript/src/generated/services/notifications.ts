/**
 * Notifications service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export type Notification = components["schemas"]["Notification"];
export type NotificationTray = components["schemas"]["NotificationTray"];

export interface ListNotificationsOptions extends PaginationOptions {
  read?: boolean;
}

export interface BulkReadNotificationsRequest {
  notificationIds?: string[];
}

export interface TrayNotificationtrayOptions extends PaginationOptions {
  includeRead?: boolean;
}

export class NotificationsService extends BaseService {

  /**
   * ListNotifications
   */
  async list(options?: ListNotificationsOptions): Promise<ListResult<Notification>> {
    return this.requestPaginated(
      {
        service: "Notifications",
        operation: "ListNotifications",
        resourceType: "notifications",
        isMutation: false,
      },
      () => this.client.GET("/notifications.json" as never, {
        params: { query: { read: options?.read } },
      } as never),
      options,
    );
  }

  /**
   * BulkReadNotifications
   */
  async bulkRead(body?: BulkReadNotificationsRequest): Promise<void> {
    return this.request(
      {
        service: "Read notifications",
        operation: "BulkReadNotifications",
        resourceType: "read_notifications",
        isMutation: true,
      },
      () => this.client.POST("/notifications/bulk_reading.json" as never, {
        body: { notification_ids: body?.notificationIds } as never,
      } as never),
    );
  }

  /**
   * GetNotificationTray
   */
  async tray(options?: TrayNotificationtrayOptions): Promise<NotificationTray> {
    return this.request(
      {
        service: "Notification tray",
        operation: "GetNotificationTray",
        resourceType: "notification_tray",
        isMutation: false,
      },
      () => this.client.GET("/notifications/tray.json" as never, {
        params: { query: { include_read: options?.includeRead } },
      } as never),
    );
  }

  /**
   * UnreadNotification
   */
  async unread(notificationId: string): Promise<void> {
    return this.request(
      {
        service: "Notification",
        operation: "UnreadNotification",
        resourceType: "notification",
        isMutation: true,
      },
      () => this.client.DELETE("/notifications/{notificationId}/reading.json" as never, {
        params: { path: { notificationId } },
      } as never),
    );
  }

  /**
   * ReadNotification
   */
  async read(notificationId: string): Promise<void> {
    return this.request(
      {
        service: "Notification",
        operation: "ReadNotification",
        resourceType: "notification",
        isMutation: true,
      },
      () => this.client.POST("/notifications/{notificationId}/reading.json" as never, {
        params: { path: { notificationId } },
      } as never),
    );
  }
}
