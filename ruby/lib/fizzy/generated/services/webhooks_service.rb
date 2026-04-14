# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Webhooks operations
    #
    # @generated from OpenAPI spec
    class WebhooksService < BaseService

      # list operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @return [Hash] response data
      def list(account_id:, board_id:)
        with_operation(service: "webhooks", operation: "ListWebhooks", is_mutation: false, resource_id: board_id) do
          http_get("/#{account_id}/boards/#{board_id}/webhooks.json").json
        end
      end

      # create operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @param name [String] name
      # @param url [String] url
      # @param subscribed_actions [Array, nil] subscribed actions
      # @return [Hash] response data
      def create(account_id:, board_id:, name:, url:, subscribed_actions: nil)
        with_operation(service: "webhooks", operation: "CreateWebhook", is_mutation: true, resource_id: board_id) do
          http_post("/#{account_id}/boards/#{board_id}/webhooks.json", body: compact_params(name: name, url: url, subscribed_actions: subscribed_actions)).json
        end
      end

      # get operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @param webhook_id [String] webhook id ID
      # @return [Hash] response data
      def get(account_id:, board_id:, webhook_id:)
        with_operation(service: "webhooks", operation: "GetWebhook", is_mutation: false, resource_id: webhook_id) do
          http_get("/#{account_id}/boards/#{board_id}/webhooks/#{webhook_id}").json
        end
      end

      # update operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @param webhook_id [String] webhook id ID
      # @param name [String, nil] name
      # @param url [String, nil] url
      # @param subscribed_actions [Array, nil] subscribed actions
      # @return [Hash] response data
      def update(account_id:, board_id:, webhook_id:, name: nil, url: nil, subscribed_actions: nil)
        with_operation(service: "webhooks", operation: "UpdateWebhook", is_mutation: true, resource_id: webhook_id) do
          http_patch("/#{account_id}/boards/#{board_id}/webhooks/#{webhook_id}", body: compact_params(name: name, url: url, subscribed_actions: subscribed_actions)).json
        end
      end

      # delete operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @param webhook_id [String] webhook id ID
      # @return [void]
      def delete(account_id:, board_id:, webhook_id:)
        with_operation(service: "webhooks", operation: "DeleteWebhook", is_mutation: true, resource_id: webhook_id) do
          http_delete("/#{account_id}/boards/#{board_id}/webhooks/#{webhook_id}")
          nil
        end
      end

      # activate operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @param webhook_id [String] webhook id ID
      # @return [void]
      def activate(account_id:, board_id:, webhook_id:)
        with_operation(service: "webhooks", operation: "ActivateWebhook", is_mutation: true, resource_id: webhook_id) do
          http_post("/#{account_id}/boards/#{board_id}/webhooks/#{webhook_id}/activation.json", retryable: true)
          nil
        end
      end

      # list_webhook_deliveries operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @param webhook_id [String] webhook id ID
      # @return [Enumerator<Hash>] paginated results
      def list_webhook_deliveries(account_id:, board_id:, webhook_id:)
        wrap_paginated(service: "webhooks", operation: "ListWebhookDeliveries", is_mutation: false, resource_id: webhook_id) do
          paginate("/#{account_id}/boards/#{board_id}/webhooks/#{webhook_id}/deliveries.json")
        end
      end
    end
  end
end
