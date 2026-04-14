# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Boards operations
    #
    # @generated from OpenAPI spec
    class BoardsService < BaseService

      # list operation
      # @param account_id [String] account id ID
      # @return [Enumerator<Hash>] paginated results
      def list(account_id:)
        wrap_paginated(service: "boards", operation: "ListBoards", is_mutation: false, resource_id: account_id) do
          paginate("/#{account_id}/boards.json")
        end
      end

      # create operation
      # @param account_id [String] account id ID
      # @param name [String] name
      # @param all_access [Boolean, nil] all access
      # @param auto_postpone_period_in_days [Integer, nil] auto postpone period in days
      # @param public_description [String, nil] public description
      # @return [Hash] response data
      def create(account_id:, name:, all_access: nil, auto_postpone_period_in_days: nil, public_description: nil)
        with_operation(service: "boards", operation: "CreateBoard", is_mutation: true, resource_id: account_id) do
          http_post("/#{account_id}/boards.json", body: compact_params(name: name, all_access: all_access, auto_postpone_period_in_days: auto_postpone_period_in_days, public_description: public_description)).json
        end
      end

      # get operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @return [Hash] response data
      def get(account_id:, board_id:)
        with_operation(service: "boards", operation: "GetBoard", is_mutation: false, resource_id: board_id) do
          http_get("/#{account_id}/boards/#{board_id}").json
        end
      end

      # update operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @param name [String, nil] name
      # @param all_access [Boolean, nil] all access
      # @param auto_postpone_period_in_days [Integer, nil] auto postpone period in days
      # @param public_description [String, nil] public description
      # @param user_ids [Array, nil] user ids
      # @return [Hash] response data
      def update(account_id:, board_id:, name: nil, all_access: nil, auto_postpone_period_in_days: nil, public_description: nil, user_ids: nil)
        with_operation(service: "boards", operation: "UpdateBoard", is_mutation: true, resource_id: board_id) do
          http_patch("/#{account_id}/boards/#{board_id}", body: compact_params(name: name, all_access: all_access, auto_postpone_period_in_days: auto_postpone_period_in_days, public_description: public_description, user_ids: user_ids)).json
        end
      end

      # delete operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @return [void]
      def delete(account_id:, board_id:)
        with_operation(service: "boards", operation: "DeleteBoard", is_mutation: true, resource_id: board_id) do
          http_delete("/#{account_id}/boards/#{board_id}")
          nil
        end
      end

      # list_board_accesses operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @param page [Integer, nil] page
      # @return [Hash] response data
      def list_board_accesses(account_id:, board_id:, page: nil)
        with_operation(service: "boards", operation: "ListBoardAccesses", is_mutation: false, resource_id: board_id) do
          http_get("/#{account_id}/boards/#{board_id}/accesses.json", params: compact_params(page: page)).json
        end
      end

      # publish_board operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @return [void]
      def publish_board(account_id:, board_id:)
        with_operation(service: "boards", operation: "PublishBoard", is_mutation: true, resource_id: board_id) do
          http_post("/#{account_id}/boards/#{board_id}/publication.json", retryable: true)
          nil
        end
      end

      # unpublish_board operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @return [void]
      def unpublish_board(account_id:, board_id:)
        with_operation(service: "boards", operation: "UnpublishBoard", is_mutation: true, resource_id: board_id) do
          http_delete("/#{account_id}/boards/#{board_id}/publication.json")
          nil
        end
      end
    end
  end
end
