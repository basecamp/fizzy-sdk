/**
 * Users service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export type User = components["schemas"]["User"];

export interface UpdateUserRequest {
  /** Display name */
  name?: string;
}

export interface RequestEmailAddressChangeRequest {
  emailAddress: string;
}

export class UsersService extends BaseService {

  /**
   * ListUsers
   */
  async list(options?: PaginationOptions): Promise<ListResult<User>> {
    return this.requestPaginated(
      {
        service: "Users",
        operation: "ListUsers",
        resourceType: "users",
        isMutation: false,
      },
      () => this.client.GET("/users.json" as never, {
      } as never),
      options,
    );
  }

  /**
   * DeactivateUser
   */
  async deactivate(userId: string): Promise<void> {
    return this.request(
      {
        service: "User",
        operation: "DeactivateUser",
        resourceType: "user",
        isMutation: true,
      },
      () => this.client.DELETE("/users/{userId}" as never, {
        params: { path: { userId } },
      } as never),
    );
  }

  /**
   * GetUser
   */
  async get(userId: string): Promise<User> {
    return this.request(
      {
        service: "User",
        operation: "GetUser",
        resourceType: "user",
        isMutation: false,
      },
      () => this.client.GET("/users/{userId}" as never, {
        params: { path: { userId } },
      } as never),
    );
  }

  /**
   * UpdateUser
   */
  async update(userId: string, body?: UpdateUserRequest): Promise<User> {
    return this.request(
      {
        service: "User",
        operation: "UpdateUser",
        resourceType: "user",
        isMutation: true,
      },
      () => this.client.PATCH("/users/{userId}" as never, {
        params: { path: { userId } },
        body: { name: body?.name } as never,
      } as never),
    );
  }

  /**
   * CreateUserDataExport
   */
  async createUserDataExport(userId: string): Promise<components["schemas"]["DataExport"]> {
    return this.request(
      {
        service: "User data export",
        operation: "CreateUserDataExport",
        resourceType: "user_data_export",
        isMutation: true,
      },
      () => this.client.POST("/users/{userId}/data_exports.json" as never, {
        params: { path: { userId } },
      } as never),
    );
  }

  /**
   * GetUserDataExport
   */
  async userDataExport(userId: string, exportId: string): Promise<components["schemas"]["DataExport"]> {
    return this.request(
      {
        service: "User data export",
        operation: "GetUserDataExport",
        resourceType: "user_data_export",
        isMutation: false,
      },
      () => this.client.GET("/users/{userId}/data_exports/{exportId}" as never, {
        params: { path: { userId, exportId } },
      } as never),
    );
  }

  /**
   * RequestEmailAddressChange
   */
  async requestEmailAddressChange(userId: string, body: RequestEmailAddressChangeRequest): Promise<void> {
    return this.request(
      {
        service: "Requestemailaddresschange",
        operation: "RequestEmailAddressChange",
        resourceType: "requestemailaddresschange",
        isMutation: true,
      },
      () => this.client.POST("/users/{userId}/email_addresses.json" as never, {
        params: { path: { userId } },
        body: { email_address: body.emailAddress } as never,
      } as never),
    );
  }

  /**
   * ConfirmEmailAddressChange
   */
  async confirmEmailAddressChange(userId: string, emailAddressToken: string): Promise<void> {
    return this.request(
      {
        service: "Confirmemailaddresschange",
        operation: "ConfirmEmailAddressChange",
        resourceType: "confirmemailaddresschange",
        isMutation: true,
      },
      () => this.client.POST("/users/{userId}/email_addresses/{emailAddressToken}/confirmation.json" as never, {
        params: { path: { userId, emailAddressToken } },
      } as never),
    );
  }
}
