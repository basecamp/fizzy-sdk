# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Tags operations
    #
    # @generated from OpenAPI spec
    class TagsService < BaseService

      # list operation
      # @param account_id [String] account id ID
      # @return [Enumerator<Hash>] paginated results
      def list(account_id:)
        wrap_paginated(service: "tags", operation: "ListTags", is_mutation: false, resource_id: account_id) do
          paginate("/#{account_id}/tags.json")
        end
      end
    end
  end
end
