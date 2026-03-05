/**
 * Users service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export type User = components["schemas"]["User"];

export interface UpdateUserRequest {
  /** Display name */
  name?: string;
  /** Role */
  role?: string;
}

export class UsersService extends BaseService {

  async list(options?: PaginationOptions): Promise<ListResult<User>> {
    return this.requestPaginated(
      { service: "Users", operation: "List", resourceType: "user", isMutation: false },
      () => this.client.GET("/users.json" as never, {} as never),
      options,
    );
  }

  async get(userId: number): Promise<User> {
    return this.request(
      { service: "Users", operation: "Get", resourceType: "user", isMutation: false, resourceId: userId },
      () => this.client.GET("/users/{userId}.json" as never, {
        params: { path: { userId } },
      } as never),
    );
  }

  async update(userId: number, body: UpdateUserRequest): Promise<User> {
    return this.request(
      { service: "Users", operation: "Update", resourceType: "user", isMutation: true, resourceId: userId },
      () => this.client.PUT("/users/{userId}.json" as never, {
        params: { path: { userId } },
        body: { name: body.name, role: body.role } as never,
      } as never),
    );
  }

  async deactivate(userId: number): Promise<void> {
    return this.request(
      { service: "Users", operation: "Deactivate", resourceType: "user", isMutation: true, resourceId: userId },
      () => this.client.DELETE("/users/{userId}.json" as never, {
        params: { path: { userId } },
      } as never),
    );
  }
}
