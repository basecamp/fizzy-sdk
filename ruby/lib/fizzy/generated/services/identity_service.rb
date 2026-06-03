# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Identity operations
    #
    # @generated from OpenAPI spec
    class IdentityService < BaseService

      # me operation
      # @return [Hash] response data
      def me()
        with_operation(service: "identity", operation: "GetMyIdentity", is_mutation: false) do
          http_get("/my/identity.json").json
        end
      end

      # update_timezone operation
      # @param account_id [String] account id ID
      # @param timezone_name [String] timezone name
      # @return [void]
      def update_timezone(account_id:, timezone_name:)
        with_operation(service: "identity", operation: "UpdateMyTimezone", is_mutation: true, resource_id: account_id) do
          http_patch("/#{account_id}/my/timezone.json", body: compact_params(timezone_name: timezone_name))
          nil
        end
      end
    end
  end
end
