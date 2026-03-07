/**
 * Webhooks service for the Fizzy API.
 *
 * @generated from OpenAPI spec - do not edit directly
 * Run `npm run generate` to regenerate.
 */

import { BaseService, type FetchResponse } from "../../services/base.js";
import { ListResult, type PaginationOptions } from "../../pagination.js";
import type { components } from "../schema.js";

export type Webhook = components["schemas"]["Webhook"];

export interface CreateWebhookRequest {
  /** Display name */
  name: string;
  url: string;
  subscribedActions?: string[];
}

export interface UpdateWebhookRequest {
  /** Display name */
  name?: string;
  url?: string;
  subscribedActions?: string[];
}

export class WebhooksService extends BaseService {

  /**
   * ListWebhooks
   */
  async list(boardId: string): Promise<ListResult<Webhook>> {
    return this.request(
      {
        service: "Webhooks",
        operation: "ListWebhooks",
        resourceType: "webhooks",
        isMutation: false,
      },
      () => this.client.GET("/boards/{boardId}/webhooks.json" as never, {
        params: { path: { boardId } },
      } as never),
    );
  }

  /**
   * CreateWebhook
   */
  async create(boardId: string, body: CreateWebhookRequest): Promise<Webhook> {
    return this.request(
      {
        service: "Webhook",
        operation: "CreateWebhook",
        resourceType: "webhook",
        isMutation: true,
      },
      () => this.client.POST("/boards/{boardId}/webhooks.json" as never, {
        params: { path: { boardId } },
        body: { name: body.name, url: body.url, subscribed_actions: body.subscribedActions } as never,
      } as never),
    );
  }

  /**
   * DeleteWebhook
   */
  async delete(boardId: string, webhookId: string): Promise<void> {
    return this.request(
      {
        service: "Webhook",
        operation: "DeleteWebhook",
        resourceType: "webhook",
        isMutation: true,
      },
      () => this.client.DELETE("/boards/{boardId}/webhooks/{webhookId}" as never, {
        params: { path: { boardId, webhookId } },
      } as never),
    );
  }

  /**
   * GetWebhook
   */
  async get(boardId: string, webhookId: string): Promise<Webhook> {
    return this.request(
      {
        service: "Webhook",
        operation: "GetWebhook",
        resourceType: "webhook",
        isMutation: false,
      },
      () => this.client.GET("/boards/{boardId}/webhooks/{webhookId}" as never, {
        params: { path: { boardId, webhookId } },
      } as never),
    );
  }

  /**
   * UpdateWebhook
   */
  async update(boardId: string, webhookId: string, body?: UpdateWebhookRequest): Promise<Webhook> {
    return this.request(
      {
        service: "Webhook",
        operation: "UpdateWebhook",
        resourceType: "webhook",
        isMutation: true,
      },
      () => this.client.PATCH("/boards/{boardId}/webhooks/{webhookId}" as never, {
        params: { path: { boardId, webhookId } },
        body: { name: body?.name, url: body?.url, subscribed_actions: body?.subscribedActions } as never,
      } as never),
    );
  }

  /**
   * ActivateWebhook
   */
  async activate(boardId: string, webhookId: string): Promise<void> {
    return this.request(
      {
        service: "Webhook",
        operation: "ActivateWebhook",
        resourceType: "webhook",
        isMutation: true,
      },
      () => this.client.POST("/boards/{boardId}/webhooks/{webhookId}/activation.json" as never, {
        params: { path: { boardId, webhookId } },
      } as never),
    );
  }
}
