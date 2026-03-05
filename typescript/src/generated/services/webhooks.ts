/**
 * Webhooks service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export type Webhook = components["schemas"]["Webhook"];

export interface CreateWebhookRequest {
  /** Webhook delivery URL */
  url: string;
  /** Event types to subscribe to */
  events?: string[];
}

export interface UpdateWebhookRequest {
  /** Webhook delivery URL */
  url?: string;
  /** Event types to subscribe to */
  events?: string[];
}

export class WebhooksService extends BaseService {

  async list(options?: PaginationOptions): Promise<ListResult<Webhook>> {
    return this.requestPaginated(
      { service: "Webhooks", operation: "List", resourceType: "webhook", isMutation: false },
      () => this.client.GET("/webhooks.json" as never, {} as never),
      options,
    );
  }

  async create(body: CreateWebhookRequest): Promise<Webhook> {
    return this.request(
      { service: "Webhooks", operation: "Create", resourceType: "webhook", isMutation: true },
      () => this.client.POST("/webhooks.json" as never, {
        body: { url: body.url, events: body.events } as never,
      } as never),
    );
  }

  async get(webhookId: number): Promise<Webhook> {
    return this.request(
      { service: "Webhooks", operation: "Get", resourceType: "webhook", isMutation: false, resourceId: webhookId },
      () => this.client.GET("/webhooks/{webhookId}.json" as never, {
        params: { path: { webhookId } },
      } as never),
    );
  }

  async update(webhookId: number, body: UpdateWebhookRequest): Promise<Webhook> {
    return this.request(
      { service: "Webhooks", operation: "Update", resourceType: "webhook", isMutation: true, resourceId: webhookId },
      () => this.client.PUT("/webhooks/{webhookId}.json" as never, {
        params: { path: { webhookId } },
        body: { url: body.url, events: body.events } as never,
      } as never),
    );
  }

  async delete(webhookId: number): Promise<void> {
    return this.request(
      { service: "Webhooks", operation: "Delete", resourceType: "webhook", isMutation: true, resourceId: webhookId },
      () => this.client.DELETE("/webhooks/{webhookId}.json" as never, {
        params: { path: { webhookId } },
      } as never),
    );
  }

  async activate(webhookId: number): Promise<Webhook> {
    return this.request(
      { service: "Webhooks", operation: "Activate", resourceType: "webhook", isMutation: true, resourceId: webhookId },
      () => this.client.PUT("/webhooks/{webhookId}/activate.json" as never, {
        params: { path: { webhookId } },
      } as never),
    );
  }
}
