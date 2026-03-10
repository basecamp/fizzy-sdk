/**
 * Miscellaneous service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export interface CreateAccessTokenRequest {
  /** Rich text description (HTML) */
  description: string;
  permission: string;
}

export interface UpdateAccountEntropyRequest {
  autoPostponePeriodInDays?: number;
}

export interface UpdateJoinCodeRequest {
  usageLimit?: number;
}

export interface UpdateAccountSettingsRequest {
  /** Display name */
  name?: string;
}

export interface UpdateBoardEntropyRequest {
  autoPostponePeriodInDays?: number;
}

export interface UpdateBoardInvolvementRequest {
  involvement?: string;
}

export interface UpdateNotificationSettingsRequest {
  bundleEmailFrequency?: string;
}

export interface CreatePushSubscriptionRequest {
  endpoint: string;
  p256dhKey: string;
  authKey: string;
}

export interface UpdateUserRoleRequest {
  role: string;
}

export class MiscellaneousService extends BaseService {

  /**
   * ListAccessTokens
   */
  async listAccessTokens(): Promise<ListResult<components["schemas"]["AccessToken"]>> {
    return this.request(
      {
        service: "Access tokens",
        operation: "ListAccessTokens",
        resourceType: "access_tokens",
        isMutation: false,
      },
      () => this.client.GET("/my/access_tokens.json" as never, {
      } as never),
    );
  }

  /**
   * CreateAccessToken
   */
  async createAccessToken(body: CreateAccessTokenRequest): Promise<components["schemas"]["AccessToken"]> {
    return this.request(
      {
        service: "Access token",
        operation: "CreateAccessToken",
        resourceType: "access_token",
        isMutation: true,
      },
      () => this.client.POST("/my/access_tokens.json" as never, {
        body: { description: body.description, permission: body.permission } as never,
      } as never),
    );
  }

  /**
   * DeleteAccessToken
   */
  async deleteAccessToken(accessTokenId: string): Promise<void> {
    return this.request(
      {
        service: "Access token",
        operation: "DeleteAccessToken",
        resourceType: "access_token",
        isMutation: true,
      },
      () => this.client.DELETE("/my/access_tokens/{accessTokenId}" as never, {
        params: { path: { accessTokenId } },
      } as never),
    );
  }

  /**
   * UpdateAccountEntropy
   */
  async updateAccountEntropy(body?: UpdateAccountEntropyRequest): Promise<components["schemas"]["AccountSettings"]> {
    return this.request(
      {
        service: "Account entropy",
        operation: "UpdateAccountEntropy",
        resourceType: "account_entropy",
        isMutation: true,
      },
      () => this.client.PUT("/account/entropy.json" as never, {
        body: { auto_postpone_period_in_days: body?.autoPostponePeriodInDays } as never,
      } as never),
    );
  }

  /**
   * CreateAccountExport
   */
  async createAccountExport(): Promise<components["schemas"]["AccountExport"]> {
    return this.request(
      {
        service: "Account export",
        operation: "CreateAccountExport",
        resourceType: "account_export",
        isMutation: true,
      },
      () => this.client.POST("/account/exports.json" as never, {
      } as never),
    );
  }

  /**
   * GetAccountExport
   */
  async accountExport(exportId: string): Promise<components["schemas"]["AccountExport"]> {
    return this.request(
      {
        service: "Account export",
        operation: "GetAccountExport",
        resourceType: "account_export",
        isMutation: false,
      },
      () => this.client.GET("/account/exports/{exportId}" as never, {
        params: { path: { exportId } },
      } as never),
    );
  }

  /**
   * ResetJoinCode
   */
  async resetJoinCode(): Promise<void> {
    return this.request(
      {
        service: "Resetjoincode",
        operation: "ResetJoinCode",
        resourceType: "resetjoincode",
        isMutation: true,
      },
      () => this.client.DELETE("/account/join_code.json" as never, {
      } as never),
    );
  }

  /**
   * GetJoinCode
   */
  async joinCode(): Promise<components["schemas"]["JoinCode"]> {
    return this.request(
      {
        service: "Join code",
        operation: "GetJoinCode",
        resourceType: "join_code",
        isMutation: false,
      },
      () => this.client.GET("/account/join_code.json" as never, {
      } as never),
    );
  }

  /**
   * UpdateJoinCode
   */
  async updateJoinCode(body?: UpdateJoinCodeRequest): Promise<void> {
    return this.request(
      {
        service: "Join code",
        operation: "UpdateJoinCode",
        resourceType: "join_code",
        isMutation: true,
      },
      () => this.client.PATCH("/account/join_code.json" as never, {
        body: { usage_limit: body?.usageLimit } as never,
      } as never),
    );
  }

  /**
   * GetAccountSettings
   */
  async accountSettings(): Promise<components["schemas"]["AccountSettings"]> {
    return this.request(
      {
        service: "Account settings",
        operation: "GetAccountSettings",
        resourceType: "account_settings",
        isMutation: false,
      },
      () => this.client.GET("/account/settings.json" as never, {
      } as never),
    );
  }

  /**
   * UpdateAccountSettings
   */
  async updateAccountSettings(body?: UpdateAccountSettingsRequest): Promise<void> {
    return this.request(
      {
        service: "Account settings",
        operation: "UpdateAccountSettings",
        resourceType: "account_settings",
        isMutation: true,
      },
      () => this.client.PATCH("/account/settings.json" as never, {
        body: { name: body?.name } as never,
      } as never),
    );
  }

  /**
   * UpdateBoardEntropy
   */
  async updateBoardEntropy(boardId: string, body?: UpdateBoardEntropyRequest): Promise<components["schemas"]["Board"]> {
    return this.request(
      {
        service: "Board entropy",
        operation: "UpdateBoardEntropy",
        resourceType: "board_entropy",
        isMutation: true,
      },
      () => this.client.PUT("/boards/{boardId}/entropy.json" as never, {
        params: { path: { boardId } },
        body: { auto_postpone_period_in_days: body?.autoPostponePeriodInDays } as never,
      } as never),
    );
  }

  /**
   * UpdateBoardInvolvement
   */
  async updateBoardInvolvement(boardId: string, body?: UpdateBoardInvolvementRequest): Promise<void> {
    return this.request(
      {
        service: "Board involvement",
        operation: "UpdateBoardInvolvement",
        resourceType: "board_involvement",
        isMutation: true,
      },
      () => this.client.PATCH("/boards/{boardId}/involvement.json" as never, {
        params: { path: { boardId } },
        body: { involvement: body?.involvement } as never,
      } as never),
    );
  }

  /**
   * MarkCardUnread
   */
  async markCardUnread(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Markcardunread",
        operation: "MarkCardUnread",
        resourceType: "markcardunread",
        isMutation: true,
      },
      () => this.client.DELETE("/cards/{cardNumber}/reading.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * MarkCardRead
   */
  async markCardRead(cardNumber: number): Promise<void> {
    return this.request(
      {
        service: "Markcardread",
        operation: "MarkCardRead",
        resourceType: "markcardread",
        isMutation: true,
      },
      () => this.client.POST("/cards/{cardNumber}/reading.json" as never, {
        params: { path: { cardNumber } },
      } as never),
    );
  }

  /**
   * MoveColumnLeft
   */
  async moveColumnLeft(columnId: string): Promise<void> {
    return this.request(
      {
        service: "Column left",
        operation: "MoveColumnLeft",
        resourceType: "column_left",
        isMutation: true,
      },
      () => this.client.POST("/columns/{columnId}/left_position.json" as never, {
        params: { path: { columnId } },
      } as never),
    );
  }

  /**
   * MoveColumnRight
   */
  async moveColumnRight(columnId: string): Promise<void> {
    return this.request(
      {
        service: "Column right",
        operation: "MoveColumnRight",
        resourceType: "column_right",
        isMutation: true,
      },
      () => this.client.POST("/columns/{columnId}/right_position.json" as never, {
        params: { path: { columnId } },
      } as never),
    );
  }

  /**
   * GetNotificationSettings
   */
  async notificationSettings(): Promise<components["schemas"]["NotificationSettings"]> {
    return this.request(
      {
        service: "Notification settings",
        operation: "GetNotificationSettings",
        resourceType: "notification_settings",
        isMutation: false,
      },
      () => this.client.GET("/notifications/settings.json" as never, {
      } as never),
    );
  }

  /**
   * UpdateNotificationSettings
   */
  async updateNotificationSettings(body?: UpdateNotificationSettingsRequest): Promise<void> {
    return this.request(
      {
        service: "Notification settings",
        operation: "UpdateNotificationSettings",
        resourceType: "notification_settings",
        isMutation: true,
      },
      () => this.client.PATCH("/notifications/settings.json" as never, {
        body: { bundle_email_frequency: body?.bundleEmailFrequency } as never,
      } as never),
    );
  }

  /**
   * DeleteUserAvatar
   */
  async deleteUserAvatar(userId: string): Promise<void> {
    return this.request(
      {
        service: "User avatar",
        operation: "DeleteUserAvatar",
        resourceType: "user_avatar",
        isMutation: true,
      },
      () => this.client.DELETE("/users/{userId}/avatar" as never, {
        params: { path: { userId } },
      } as never),
    );
  }

  /**
   * CreatePushSubscription
   */
  async createPushSubscription(userId: string, body: CreatePushSubscriptionRequest): Promise<void> {
    return this.request(
      {
        service: "Push subscription",
        operation: "CreatePushSubscription",
        resourceType: "push_subscription",
        isMutation: true,
      },
      () => this.client.POST("/users/{userId}/push_subscriptions.json" as never, {
        params: { path: { userId } },
        body: { endpoint: body.endpoint, p256dh_key: body.p256dhKey, auth_key: body.authKey } as never,
      } as never),
    );
  }

  /**
   * DeletePushSubscription
   */
  async deletePushSubscription(userId: string, pushSubscriptionId: string): Promise<void> {
    return this.request(
      {
        service: "Push subscription",
        operation: "DeletePushSubscription",
        resourceType: "push_subscription",
        isMutation: true,
      },
      () => this.client.DELETE("/users/{userId}/push_subscriptions/{pushSubscriptionId}" as never, {
        params: { path: { userId, pushSubscriptionId } },
      } as never),
    );
  }

  /**
   * UpdateUserRole
   */
  async updateUserRole(userId: string, body: UpdateUserRoleRequest): Promise<void> {
    return this.request(
      {
        service: "User role",
        operation: "UpdateUserRole",
        resourceType: "user_role",
        isMutation: true,
      },
      () => this.client.PATCH("/users/{userId}/role.json" as never, {
        params: { path: { userId } },
        body: { role: body.role } as never,
      } as never),
    );
  }
}
