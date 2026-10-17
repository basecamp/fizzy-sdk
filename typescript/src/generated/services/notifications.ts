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

export interface BulkReadNotificationsRequest {
  /** Ignored: Notifications::BulkReadingsController reads no ids and marks every unread notification read whatever this holds. */
  notificationIds?: string[];
}

export interface TrayNotificationtrayOptions extends PaginationOptions {
  includeRead?: boolean;
}

export class NotificationsService extends BaseService {

  /**
   * Lists the caller's notifications. It takes no read/unread filter: the first page holds up to 100 unread notifications followed by a page of read ones, and later pages hold read ones only.
   */
  async list(options?: PaginationOptions): Promise<ListResult<Notification>> {
    return this.requestPaginated(
      {
        service: "Notifications",
        operation: "ListNotifications",
        resourceType: "notifications",
        isMutation: false,
      },
      () => this.client.GET("/notifications.json" as never, {
      } as never),
      options,
    );
  }

  /**
   * Marks every unread notification of the caller read. It takes no selection.
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
  async tray(options?: TrayNotificationtrayOptions): Promise<ListResult<Notification>> {
    return this.request(
      {
        service: "Notification tray",
        operation: "GetNotificationTray",
        resourceType: "notification_tray",
        isMutation: false,
      },
      () => this.client.GET("/notifications/tray.json" as never, {
        params: { query: { "include_read": options?.includeRead } },
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
