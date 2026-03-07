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
    end
  end
end
