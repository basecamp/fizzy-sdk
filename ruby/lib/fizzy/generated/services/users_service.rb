# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Users operations
    #
    # @generated from OpenAPI spec
    class UsersService < BaseService

      # list operation
      # @param account_id [String] account id ID
      # @return [Enumerator<Hash>] paginated results
      def list(account_id:)
        wrap_paginated(service: "users", operation: "ListUsers", is_mutation: false, resource_id: account_id) do
          paginate("/#{account_id}/users.json")
        end
      end

      # get operation
      # @param account_id [String] account id ID
      # @param user_id [String] user id ID
      # @return [Hash] response data
      def get(account_id:, user_id:)
        with_operation(service: "users", operation: "GetUser", is_mutation: false, resource_id: user_id) do
          http_get("/#{account_id}/users/#{user_id}").json
        end
      end

      # update operation
      # @param account_id [String] account id ID
      # @param user_id [String] user id ID
      # @param name [String, nil] name
      # @return [Hash] response data
      def update(account_id:, user_id:, name: nil)
        with_operation(service: "users", operation: "UpdateUser", is_mutation: true, resource_id: user_id) do
          http_patch("/#{account_id}/users/#{user_id}", body: compact_params(name: name)).json
        end
      end

      # deactivate operation
      # @param account_id [String] account id ID
      # @param user_id [String] user id ID
      # @return [void]
      def deactivate(account_id:, user_id:)
        with_operation(service: "users", operation: "DeactivateUser", is_mutation: true, resource_id: user_id) do
          http_delete("/#{account_id}/users/#{user_id}")
          nil
        end
      end

      # create_user_data_export operation
      # @param account_id [String] account id ID
      # @param user_id [String] user id ID
      # @return [Hash] response data
      def create_user_data_export(account_id:, user_id:)
        with_operation(service: "users", operation: "CreateUserDataExport", is_mutation: true, resource_id: user_id) do
          http_post("/#{account_id}/users/#{user_id}/data_exports.json").json
        end
      end

      # get_user_data_export operation
      # @param account_id [String] account id ID
      # @param user_id [String] user id ID
      # @param export_id [String] export id ID
      # @return [Hash] response data
      def get_user_data_export(account_id:, user_id:, export_id:)
        with_operation(service: "users", operation: "GetUserDataExport", is_mutation: false, resource_id: export_id) do
          http_get("/#{account_id}/users/#{user_id}/data_exports/#{export_id}").json
        end
      end

      # request_email_address_change operation
      # @param account_id [String] account id ID
      # @param user_id [String] user id ID
      # @param email_address [String] email address
      # @return [void]
      def request_email_address_change(account_id:, user_id:, email_address:)
        with_operation(service: "users", operation: "RequestEmailAddressChange", is_mutation: true, resource_id: user_id) do
          http_post("/#{account_id}/users/#{user_id}/email_addresses.json", body: compact_params(email_address: email_address))
          nil
        end
      end

      # confirm_email_address_change operation
      # @param account_id [String] account id ID
      # @param user_id [String] user id ID
      # @param email_address_token [String] email address token ID
      # @return [void]
      def confirm_email_address_change(account_id:, user_id:, email_address_token:)
        with_operation(service: "users", operation: "ConfirmEmailAddressChange", is_mutation: true, resource_id: email_address_token) do
          http_post("/#{account_id}/users/#{user_id}/email_addresses/#{email_address_token}/confirmation.json")
          nil
        end
      end
    end
  end
end
