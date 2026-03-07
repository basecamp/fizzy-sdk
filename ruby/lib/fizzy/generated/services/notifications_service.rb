# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Notifications operations
    #
    # @generated from OpenAPI spec
    class NotificationsService < BaseService

      # list operation
      # @param account_id [String] account id ID
      # @param read [Boolean, nil] read
      # @return [Enumerator<Hash>] paginated results
      def list(account_id:, read: nil)
        wrap_paginated(service: "notifications", operation: "ListNotifications", is_mutation: false, resource_id: account_id) do
          params = compact_params(read: read)
          paginate("/#{account_id}/notifications.json", params: params)
        end
      end

      # bulk_read operation
      # @param account_id [String] account id ID
      # @param notification_ids [Array, nil] notification ids
      # @return [void]
      def bulk_read(account_id:, notification_ids: nil)
        with_operation(service: "notifications", operation: "BulkReadNotifications", is_mutation: true, resource_id: account_id) do
          http_post("/#{account_id}/notifications/bulk_reading.json", body: compact_params(notification_ids: notification_ids))
          nil
        end
      end

      # tray operation
      # @param account_id [String] account id ID
      # @param include_read [Boolean, nil] include read
      # @return [Hash] response data
      def tray(account_id:, include_read: nil)
        with_operation(service: "notifications", operation: "GetNotificationTray", is_mutation: false, resource_id: account_id) do
          http_get("/#{account_id}/notifications/tray.json", params: compact_params(include_read: include_read)).json
        end
      end

      # read operation
      # @param account_id [String] account id ID
      # @param notification_id [String] notification id ID
      # @return [void]
      def read(account_id:, notification_id:)
        with_operation(service: "notifications", operation: "ReadNotification", is_mutation: true, resource_id: notification_id) do
          http_post("/#{account_id}/notifications/#{notification_id}/reading.json")
          nil
        end
      end

      # unread operation
      # @param account_id [String] account id ID
      # @param notification_id [String] notification id ID
      # @return [void]
      def unread(account_id:, notification_id:)
        with_operation(service: "notifications", operation: "UnreadNotification", is_mutation: true, resource_id: notification_id) do
          http_delete("/#{account_id}/notifications/#{notification_id}/reading.json")
          nil
        end
      end
    end
  end
end
