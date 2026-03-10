# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Miscellaneous operations
    #
    # @generated from OpenAPI spec
    class MiscellaneousService < BaseService

      # list_access_tokens operation
      # @return [Hash] response data
      def list_access_tokens()
        with_operation(service: "miscellaneous", operation: "ListAccessTokens", is_mutation: false) do
          http_get("/my/access_tokens.json").json
        end
      end

      # create_access_token operation
      # @param description [String] description
      # @param permission [String] permission
      # @return [Hash] response data
      def create_access_token(description:, permission:)
        with_operation(service: "miscellaneous", operation: "CreateAccessToken", is_mutation: true) do
          http_post("/my/access_tokens.json", body: compact_params(description: description, permission: permission)).json
        end
      end

      # delete_access_token operation
      # @param access_token_id [String] access token id ID
      # @return [void]
      def delete_access_token(access_token_id:)
        with_operation(service: "miscellaneous", operation: "DeleteAccessToken", is_mutation: true, resource_id: access_token_id) do
          http_delete("/my/access_tokens/#{access_token_id}")
          nil
        end
      end

      # update_account_entropy operation
      # @param account_id [String] account id ID
      # @param auto_postpone_period_in_days [Integer, nil] auto postpone period in days
      # @return [Hash] response data
      def update_account_entropy(account_id:, auto_postpone_period_in_days: nil)
        with_operation(service: "miscellaneous", operation: "UpdateAccountEntropy", is_mutation: true, resource_id: account_id) do
          http_put("/#{account_id}/account/entropy.json", body: compact_params(auto_postpone_period_in_days: auto_postpone_period_in_days)).json
        end
      end

      # create_account_export operation
      # @param account_id [String] account id ID
      # @return [Hash] response data
      def create_account_export(account_id:)
        with_operation(service: "miscellaneous", operation: "CreateAccountExport", is_mutation: true, resource_id: account_id) do
          http_post("/#{account_id}/account/exports.json").json
        end
      end

      # get_account_export operation
      # @param account_id [String] account id ID
      # @param export_id [String] export id ID
      # @return [Hash] response data
      def get_account_export(account_id:, export_id:)
        with_operation(service: "miscellaneous", operation: "GetAccountExport", is_mutation: false, resource_id: export_id) do
          http_get("/#{account_id}/account/exports/#{export_id}").json
        end
      end

      # get_join_code operation
      # @param account_id [String] account id ID
      # @return [Hash] response data
      def get_join_code(account_id:)
        with_operation(service: "miscellaneous", operation: "GetJoinCode", is_mutation: false, resource_id: account_id) do
          http_get("/#{account_id}/account/join_code.json").json
        end
      end

      # update_join_code operation
      # @param account_id [String] account id ID
      # @param usage_limit [Integer, nil] usage limit
      # @return [void]
      def update_join_code(account_id:, usage_limit: nil)
        with_operation(service: "miscellaneous", operation: "UpdateJoinCode", is_mutation: true, resource_id: account_id) do
          http_patch("/#{account_id}/account/join_code.json", body: compact_params(usage_limit: usage_limit))
          nil
        end
      end

      # reset_join_code operation
      # @param account_id [String] account id ID
      # @return [void]
      def reset_join_code(account_id:)
        with_operation(service: "miscellaneous", operation: "ResetJoinCode", is_mutation: true, resource_id: account_id) do
          http_delete("/#{account_id}/account/join_code.json")
          nil
        end
      end

      # get_account_settings operation
      # @param account_id [String] account id ID
      # @return [Hash] response data
      def get_account_settings(account_id:)
        with_operation(service: "miscellaneous", operation: "GetAccountSettings", is_mutation: false, resource_id: account_id) do
          http_get("/#{account_id}/account/settings.json").json
        end
      end

      # update_account_settings operation
      # @param account_id [String] account id ID
      # @param name [String, nil] name
      # @return [void]
      def update_account_settings(account_id:, name: nil)
        with_operation(service: "miscellaneous", operation: "UpdateAccountSettings", is_mutation: true, resource_id: account_id) do
          http_patch("/#{account_id}/account/settings.json", body: compact_params(name: name))
          nil
        end
      end

      # update_board_entropy operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @param auto_postpone_period_in_days [Integer, nil] auto postpone period in days
      # @return [Hash] response data
      def update_board_entropy(account_id:, board_id:, auto_postpone_period_in_days: nil)
        with_operation(service: "miscellaneous", operation: "UpdateBoardEntropy", is_mutation: true, resource_id: board_id) do
          http_put("/#{account_id}/boards/#{board_id}/entropy.json", body: compact_params(auto_postpone_period_in_days: auto_postpone_period_in_days)).json
        end
      end

      # update_board_involvement operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @param involvement [String, nil] involvement
      # @return [void]
      def update_board_involvement(account_id:, board_id:, involvement: nil)
        with_operation(service: "miscellaneous", operation: "UpdateBoardInvolvement", is_mutation: true, resource_id: board_id) do
          http_patch("/#{account_id}/boards/#{board_id}/involvement.json", body: compact_params(involvement: involvement))
          nil
        end
      end

      # mark_card_read operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def mark_card_read(account_id:, card_number:)
        with_operation(service: "miscellaneous", operation: "MarkCardRead", is_mutation: true, resource_id: card_number) do
          http_post("/#{account_id}/cards/#{card_number}/reading.json", retryable: true)
          nil
        end
      end

      # mark_card_unread operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def mark_card_unread(account_id:, card_number:)
        with_operation(service: "miscellaneous", operation: "MarkCardUnread", is_mutation: true, resource_id: card_number) do
          http_delete("/#{account_id}/cards/#{card_number}/reading.json")
          nil
        end
      end

      # move_column_left operation
      # @param account_id [String] account id ID
      # @param column_id [String] column id ID
      # @return [void]
      def move_column_left(account_id:, column_id:)
        with_operation(service: "miscellaneous", operation: "MoveColumnLeft", is_mutation: true, resource_id: column_id) do
          http_post("/#{account_id}/columns/#{column_id}/left_position.json", retryable: true)
          nil
        end
      end

      # move_column_right operation
      # @param account_id [String] account id ID
      # @param column_id [String] column id ID
      # @return [void]
      def move_column_right(account_id:, column_id:)
        with_operation(service: "miscellaneous", operation: "MoveColumnRight", is_mutation: true, resource_id: column_id) do
          http_post("/#{account_id}/columns/#{column_id}/right_position.json", retryable: true)
          nil
        end
      end

      # get_notification_settings operation
      # @param account_id [String] account id ID
      # @return [Hash] response data
      def get_notification_settings(account_id:)
        with_operation(service: "miscellaneous", operation: "GetNotificationSettings", is_mutation: false, resource_id: account_id) do
          http_get("/#{account_id}/notifications/settings.json").json
        end
      end

      # update_notification_settings operation
      # @param account_id [String] account id ID
      # @param bundle_email_frequency [String, nil] bundle email frequency
      # @return [void]
      def update_notification_settings(account_id:, bundle_email_frequency: nil)
        with_operation(service: "miscellaneous", operation: "UpdateNotificationSettings", is_mutation: true, resource_id: account_id) do
          http_patch("/#{account_id}/notifications/settings.json", body: compact_params(bundle_email_frequency: bundle_email_frequency))
          nil
        end
      end

      # delete_user_avatar operation
      # @param account_id [String] account id ID
      # @param user_id [String] user id ID
      # @return [void]
      def delete_user_avatar(account_id:, user_id:)
        with_operation(service: "miscellaneous", operation: "DeleteUserAvatar", is_mutation: true, resource_id: user_id) do
          http_delete("/#{account_id}/users/#{user_id}/avatar")
          nil
        end
      end

      # create_push_subscription operation
      # @param account_id [String] account id ID
      # @param user_id [String] user id ID
      # @param endpoint [String] endpoint
      # @param p256dh_key [String] p256dh key
      # @param auth_key [String] auth key
      # @return [void]
      def create_push_subscription(account_id:, user_id:, endpoint:, p256dh_key:, auth_key:)
        with_operation(service: "miscellaneous", operation: "CreatePushSubscription", is_mutation: true, resource_id: user_id) do
          http_post("/#{account_id}/users/#{user_id}/push_subscriptions.json", body: compact_params(endpoint: endpoint, p256dh_key: p256dh_key, auth_key: auth_key))
          nil
        end
      end

      # delete_push_subscription operation
      # @param account_id [String] account id ID
      # @param user_id [String] user id ID
      # @param push_subscription_id [String] push subscription id ID
      # @return [void]
      def delete_push_subscription(account_id:, user_id:, push_subscription_id:)
        with_operation(service: "miscellaneous", operation: "DeletePushSubscription", is_mutation: true, resource_id: push_subscription_id) do
          http_delete("/#{account_id}/users/#{user_id}/push_subscriptions/#{push_subscription_id}")
          nil
        end
      end

      # update_user_role operation
      # @param account_id [String] account id ID
      # @param user_id [String] user id ID
      # @param role [String] role
      # @return [void]
      def update_user_role(account_id:, user_id:, role:)
        with_operation(service: "miscellaneous", operation: "UpdateUserRole", is_mutation: true, resource_id: user_id) do
          http_patch("/#{account_id}/users/#{user_id}/role.json", body: compact_params(role: role))
          nil
        end
      end
    end
  end
end
