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
  /** The events to deliver, from: "card_assigned", "card_closed", "card_postponed", "card_auto_postponed", "card_board_changed", "card_published", "card_reopened", "card_sent_back_to_triage", "card_triaged", "card_unassigned" and "comment_created" (Webhook::PERMITTED_ACTIONS). Unknown actions are dropped silently. A webhook created without any receives no deliveries. */
  subscribedActions?: string[];
}

export interface UpdateWebhookRequest {
  /** Display name */
  name?: string;
  /** The events to deliver, from: "card_assigned", "card_closed", "card_postponed", "card_auto_postponed", "card_board_changed", "card_published", "card_reopened", "card_sent_back_to_triage", "card_triaged", "card_unassigned" and "comment_created" (Webhook::PERMITTED_ACTIONS). Unknown actions are dropped silently. The list replaces the current subscription. */
  subscribedActions?: string[];
}

export class WebhooksService extends BaseService {

  /**
   * Lists the board's webhooks. Fizzy pages this list (a Link header with rel="next"); this operation returns the first page.
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
   * Updates a webhook's name or subscribed actions. Send at least one: the controller expects a `webhook` object, so an empty body is a 400. The URL can't change after creation; delete the webhook and create a new one.
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
        body: { name: body?.name, subscribed_actions: body?.subscribedActions } as never,
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

  /**
   * ListWebhookDeliveries
   */
  async listWebhookDeliveries(boardId: string, webhookId: string, options?: PaginationOptions): Promise<ListResult<components["schemas"]["WebhookDelivery"]>> {
    return this.requestPaginated(
      {
        service: "Webhook deliveries",
        operation: "ListWebhookDeliveries",
        resourceType: "webhook_deliveries",
        isMutation: false,
      },
      () => this.client.GET("/boards/{boardId}/webhooks/{webhookId}/deliveries.json" as never, {
        params: { path: { boardId, webhookId } },
      } as never),
      options,
    );
  }
}
