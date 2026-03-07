# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Columns operations
    #
    # @generated from OpenAPI spec
    class ColumnsService < BaseService

      # list operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @return [Hash] response data
      def list(account_id:, board_id:)
        with_operation(service: "columns", operation: "ListColumns", is_mutation: false, resource_id: board_id) do
          http_get("/#{account_id}/boards/#{board_id}/columns.json").json
        end
      end

      # create operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @param name [String] name
      # @param color [String, nil] color
      # @return [Hash] response data
      def create(account_id:, board_id:, name:, color: nil)
        with_operation(service: "columns", operation: "CreateColumn", is_mutation: true, resource_id: board_id) do
          http_post("/#{account_id}/boards/#{board_id}/columns.json", body: compact_params(name: name, color: color)).json
        end
      end

      # get operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @param column_id [String] column id ID
      # @return [Hash] response data
      def get(account_id:, board_id:, column_id:)
        with_operation(service: "columns", operation: "GetColumn", is_mutation: false, resource_id: column_id) do
          http_get("/#{account_id}/boards/#{board_id}/columns/#{column_id}").json
        end
      end

      # update operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @param column_id [String] column id ID
      # @param name [String, nil] name
      # @param color [String, nil] color
      # @return [Hash] response data
      def update(account_id:, board_id:, column_id:, name: nil, color: nil)
        with_operation(service: "columns", operation: "UpdateColumn", is_mutation: true, resource_id: column_id) do
          http_patch("/#{account_id}/boards/#{board_id}/columns/#{column_id}", body: compact_params(name: name, color: color)).json
        end
      end

      # delete operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @param column_id [String] column id ID
      # @return [void]
      def delete(account_id:, board_id:, column_id:)
        with_operation(service: "columns", operation: "DeleteColumn", is_mutation: true, resource_id: column_id) do
          http_delete("/#{account_id}/boards/#{board_id}/columns/#{column_id}")
          nil
        end
      end
    end
  end
end
