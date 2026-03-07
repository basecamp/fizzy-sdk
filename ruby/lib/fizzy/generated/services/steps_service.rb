# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Steps operations
    #
    # @generated from OpenAPI spec
    class StepsService < BaseService

      # create operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param content [String] content
      # @param completed [Boolean, nil] completed
      # @return [Hash] response data
      def create(account_id:, card_number:, content:, completed: nil)
        with_operation(service: "steps", operation: "CreateStep", is_mutation: true, resource_id: card_number) do
          http_post("/#{account_id}/cards/#{card_number}/steps.json", body: compact_params(content: content, completed: completed)).json
        end
      end

      # get operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param step_id [String] step id ID
      # @return [Hash] response data
      def get(account_id:, card_number:, step_id:)
        with_operation(service: "steps", operation: "GetStep", is_mutation: false, resource_id: step_id) do
          http_get("/#{account_id}/cards/#{card_number}/steps/#{step_id}").json
        end
      end

      # update operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param step_id [String] step id ID
      # @param content [String, nil] content
      # @param completed [Boolean, nil] completed
      # @return [Hash] response data
      def update(account_id:, card_number:, step_id:, content: nil, completed: nil)
        with_operation(service: "steps", operation: "UpdateStep", is_mutation: true, resource_id: step_id) do
          http_patch("/#{account_id}/cards/#{card_number}/steps/#{step_id}", body: compact_params(content: content, completed: completed)).json
        end
      end

      # delete operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param step_id [String] step id ID
      # @return [void]
      def delete(account_id:, card_number:, step_id:)
        with_operation(service: "steps", operation: "DeleteStep", is_mutation: true, resource_id: step_id) do
          http_delete("/#{account_id}/cards/#{card_number}/steps/#{step_id}")
          nil
        end
      end
    end
  end
end
