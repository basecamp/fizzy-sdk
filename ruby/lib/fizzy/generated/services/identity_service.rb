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
    end
  end
end
