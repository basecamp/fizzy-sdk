/**
 * Steps service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import type { components } from "../schema.js";

export type Step = components["schemas"]["Step"];

export interface CreateStepRequest {
  description: string;
  position?: number;
}

export interface UpdateStepRequest {
  description?: string;
  completed?: boolean;
  position?: number;
}

export class StepsService extends BaseService {

  async create(cardNumber: number, body: CreateStepRequest): Promise<Step> {
    return this.request(
      { service: "Steps", operation: "Create", resourceType: "step", isMutation: true },
      () => this.client.POST("/cards/{cardNumber}/steps.json" as never, {
        params: { path: { cardNumber } },
        body: { description: body.description, position: body.position } as never,
      } as never),
    );
  }

  async get(cardNumber: number, stepId: number): Promise<Step> {
    return this.request(
      { service: "Steps", operation: "Get", resourceType: "step", isMutation: false, resourceId: stepId },
      () => this.client.GET("/cards/{cardNumber}/steps/{stepId}.json" as never, {
        params: { path: { cardNumber, stepId } },
      } as never),
    );
  }

  async update(cardNumber: number, stepId: number, body: UpdateStepRequest): Promise<Step> {
    return this.request(
      { service: "Steps", operation: "Update", resourceType: "step", isMutation: true, resourceId: stepId },
      () => this.client.PUT("/cards/{cardNumber}/steps/{stepId}.json" as never, {
        params: { path: { cardNumber, stepId } },
        body: { description: body.description, completed: body.completed, position: body.position } as never,
      } as never),
    );
  }

  async delete(cardNumber: number, stepId: number): Promise<void> {
    return this.request(
      { service: "Steps", operation: "Delete", resourceType: "step", isMutation: true, resourceId: stepId },
      () => this.client.DELETE("/cards/{cardNumber}/steps/{stepId}.json" as never, {
        params: { path: { cardNumber, stepId } },
      } as never),
    );
  }
}
