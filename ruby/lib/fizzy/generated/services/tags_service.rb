# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Tags operations
    #
    # @generated from OpenAPI spec
    class TagsService < BaseService

      # list operation
      # @param account_id [String] account id ID
      # @return [Hash] response data
      def list(account_id:)
        with_operation(service: "tags", operation: "ListTags", is_mutation: false, resource_id: account_id) do
          http_get("/#{account_id}/tags.json").json
        end
      end
    end
  end
end
