/**
 * Steps service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import type { components } from "../schema.js";

export type Step = components["schemas"]["Step"];

export interface CreateStepRequest {
  /** Text content */
  content: string;
  completed?: boolean;
}

export interface UpdateStepRequest {
  /** Text content */
  content?: string;
  completed?: boolean;
}

export class StepsService extends BaseService {

  /**
   * CreateStep
   */
  async create(cardNumber: number, body: CreateStepRequest): Promise<Step> {
    return this.request(
      {
        service: "Step",
        operation: "CreateStep",
        resourceType: "step",
        isMutation: true,
      },
      () => this.client.POST("/cards/{cardNumber}/steps.json" as never, {
        params: { path: { cardNumber } },
        body: { content: body.content, completed: body.completed } as never,
      } as never),
    );
  }

  /**
   * DeleteStep
   */
  async delete(cardNumber: number, stepId: string): Promise<void> {
    return this.request(
      {
        service: "Step",
        operation: "DeleteStep",
        resourceType: "step",
        isMutation: true,
      },
      () => this.client.DELETE("/cards/{cardNumber}/steps/{stepId}" as never, {
        params: { path: { cardNumber, stepId } },
      } as never),
    );
  }

  /**
   * GetStep
   */
  async get(cardNumber: number, stepId: string): Promise<Step> {
    return this.request(
      {
        service: "Step",
        operation: "GetStep",
        resourceType: "step",
        isMutation: false,
      },
      () => this.client.GET("/cards/{cardNumber}/steps/{stepId}" as never, {
        params: { path: { cardNumber, stepId } },
      } as never),
    );
  }

  /**
   * UpdateStep
   */
  async update(cardNumber: number, stepId: string, body?: UpdateStepRequest): Promise<Step> {
    return this.request(
      {
        service: "Step",
        operation: "UpdateStep",
        resourceType: "step",
        isMutation: true,
      },
      () => this.client.PATCH("/cards/{cardNumber}/steps/{stepId}" as never, {
        params: { path: { cardNumber, stepId } },
        body: { content: body?.content, completed: body?.completed } as never,
      } as never),
    );
  }
}
