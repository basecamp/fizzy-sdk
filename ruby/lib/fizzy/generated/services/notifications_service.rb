# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Notifications operations
    #
    # @generated from OpenAPI spec
    class NotificationsService < BaseService

      # Lists the caller's notifications. It takes no read/unread filter: the first page holds up to 100 unread notifications followed by a page of read ones, and later pages hold read ones only.
      # @param account_id [String] account id ID
      # @return [Enumerator<Hash>] paginated results
      def list(account_id:)
        wrap_paginated(service: "notifications", operation: "ListNotifications", is_mutation: false, resource_id: account_id) do
          paginate("/#{account_id}/notifications.json")
        end
      end

      # Marks every unread notification of the caller read. It takes no selection.
      # @param account_id [String] account id ID
      # @param notification_ids [Array, nil] Ignored: Notifications::BulkReadingsController reads no ids and marks every unread notification read whatever this holds.
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
          http_post("/#{account_id}/notifications/#{notification_id}/reading.json", retryable: true)
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
