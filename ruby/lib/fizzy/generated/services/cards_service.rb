# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Cards operations
    #
    # @generated from OpenAPI spec
    class CardsService < BaseService

      # list operation
      # @param account_id [String] account id ID
      # @param board_id [String, nil] board id
      # @param column_id [String, nil] column id
      # @param assignee_id [String, nil] assignee id
      # @param tag [String, nil] tag
      # @param status [String, nil] status
      # @param q [String, nil] q
      # @return [Enumerator<Hash>] paginated results
      def list(account_id:, board_id: nil, column_id: nil, assignee_id: nil, tag: nil, status: nil, q: nil)
        wrap_paginated(service: "cards", operation: "ListCards", is_mutation: false, resource_id: account_id) do
          params = compact_params(board_id: board_id, column_id: column_id, assignee_id: assignee_id, tag: tag, status: status, q: q)
          paginate("/#{account_id}/cards.json", params: params)
        end
      end

      # create operation
      # @param account_id [String] account id ID
      # @param title [String] title
      # @param board_id [String, nil] board id
      # @param column_id [String, nil] column id
      # @param description [String, nil] description
      # @param assignee_ids [Array, nil] assignee ids
      # @param tag_names [Array, nil] tag names
      # @param image [String, nil] image
      # @param created_at [String, nil] created at
      # @param last_active_at [String, nil] last active at
      # @return [Hash] response data
      def create(account_id:, title:, board_id: nil, column_id: nil, description: nil, assignee_ids: nil, tag_names: nil, image: nil, created_at: nil, last_active_at: nil)
        with_operation(service: "cards", operation: "CreateCard", is_mutation: true, resource_id: account_id) do
          http_post("/#{account_id}/cards.json", body: compact_params(title: title, board_id: board_id, column_id: column_id, description: description, assignee_ids: assignee_ids, tag_names: tag_names, image: image, created_at: created_at, last_active_at: last_active_at)).json
        end
      end

      # get operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [Hash] response data
      def get(account_id:, card_number:)
        with_operation(service: "cards", operation: "GetCard", is_mutation: false, resource_id: card_number) do
          http_get("/#{account_id}/cards/#{card_number}").json
        end
      end

      # update operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param title [String, nil] title
      # @param description [String, nil] description
      # @param column_id [String, nil] column id
      # @param image [String, nil] image
      # @param created_at [String, nil] created at
      # @return [Hash] response data
      def update(account_id:, card_number:, title: nil, description: nil, column_id: nil, image: nil, created_at: nil)
        with_operation(service: "cards", operation: "UpdateCard", is_mutation: true, resource_id: card_number) do
          http_patch("/#{account_id}/cards/#{card_number}", body: compact_params(title: title, description: description, column_id: column_id, image: image, created_at: created_at)).json
        end
      end

      # delete operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def delete(account_id:, card_number:)
        with_operation(service: "cards", operation: "DeleteCard", is_mutation: true, resource_id: card_number) do
          http_delete("/#{account_id}/cards/#{card_number}")
          nil
        end
      end

      # assign operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param assignee_id [String] assignee id
      # @return [void]
      def assign(account_id:, card_number:, assignee_id:)
        with_operation(service: "cards", operation: "AssignCard", is_mutation: true, resource_id: card_number) do
          http_post("/#{account_id}/cards/#{card_number}/assignments.json", body: compact_params(assignee_id: assignee_id))
          nil
        end
      end

      # move operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param board_id [String] board id
      # @param column_id [String, nil] column id
      # @return [Hash] response data
      def move(account_id:, card_number:, board_id:, column_id: nil)
        with_operation(service: "cards", operation: "MoveCard", is_mutation: true, resource_id: card_number) do
          http_patch("/#{account_id}/cards/#{card_number}/board.json", body: compact_params(board_id: board_id, column_id: column_id)).json
        end
      end

      # close operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def close(account_id:, card_number:)
        with_operation(service: "cards", operation: "CloseCard", is_mutation: true, resource_id: card_number) do
          http_post("/#{account_id}/cards/#{card_number}/closure.json")
          nil
        end
      end

      # reopen operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def reopen(account_id:, card_number:)
        with_operation(service: "cards", operation: "ReopenCard", is_mutation: true, resource_id: card_number) do
          http_delete("/#{account_id}/cards/#{card_number}/closure.json")
          nil
        end
      end

      # gold operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def gold(account_id:, card_number:)
        with_operation(service: "cards", operation: "GoldCard", is_mutation: true, resource_id: card_number) do
          http_post("/#{account_id}/cards/#{card_number}/goldness.json")
          nil
        end
      end

      # ungold operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def ungold(account_id:, card_number:)
        with_operation(service: "cards", operation: "UngoldCard", is_mutation: true, resource_id: card_number) do
          http_delete("/#{account_id}/cards/#{card_number}/goldness.json")
          nil
        end
      end

      # delete_image operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def delete_image(account_id:, card_number:)
        with_operation(service: "cards", operation: "DeleteCardImage", is_mutation: true, resource_id: card_number) do
          http_delete("/#{account_id}/cards/#{card_number}/image.json")
          nil
        end
      end

      # postpone operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def postpone(account_id:, card_number:)
        with_operation(service: "cards", operation: "PostponeCard", is_mutation: true, resource_id: card_number) do
          http_post("/#{account_id}/cards/#{card_number}/not_now.json")
          nil
        end
      end

      # pin operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def pin(account_id:, card_number:)
        with_operation(service: "cards", operation: "PinCard", is_mutation: true, resource_id: card_number) do
          http_post("/#{account_id}/cards/#{card_number}/pin.json")
          nil
        end
      end

      # unpin operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def unpin(account_id:, card_number:)
        with_operation(service: "cards", operation: "UnpinCard", is_mutation: true, resource_id: card_number) do
          http_delete("/#{account_id}/cards/#{card_number}/pin.json")
          nil
        end
      end

      # self_assign operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def self_assign(account_id:, card_number:)
        with_operation(service: "cards", operation: "SelfAssignCard", is_mutation: true, resource_id: card_number) do
          http_post("/#{account_id}/cards/#{card_number}/self_assignment.json")
          nil
        end
      end

      # tag operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param tag_title [String] tag title
      # @return [void]
      def tag(account_id:, card_number:, tag_title:)
        with_operation(service: "cards", operation: "TagCard", is_mutation: true, resource_id: card_number) do
          http_post("/#{account_id}/cards/#{card_number}/taggings.json", body: compact_params(tag_title: tag_title))
          nil
        end
      end

      # triage operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param column_id [String, nil] column id
      # @return [void]
      def triage(account_id:, card_number:, column_id: nil)
        with_operation(service: "cards", operation: "TriageCard", is_mutation: true, resource_id: card_number) do
          http_post("/#{account_id}/cards/#{card_number}/triage.json", body: compact_params(column_id: column_id))
          nil
        end
      end

      # untriage operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def untriage(account_id:, card_number:)
        with_operation(service: "cards", operation: "UnTriageCard", is_mutation: true, resource_id: card_number) do
          http_delete("/#{account_id}/cards/#{card_number}/triage.json")
          nil
        end
      end

      # watch operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def watch(account_id:, card_number:)
        with_operation(service: "cards", operation: "WatchCard", is_mutation: true, resource_id: card_number) do
          http_post("/#{account_id}/cards/#{card_number}/watch.json")
          nil
        end
      end

      # unwatch operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def unwatch(account_id:, card_number:)
        with_operation(service: "cards", operation: "UnwatchCard", is_mutation: true, resource_id: card_number) do
          http_delete("/#{account_id}/cards/#{card_number}/watch.json")
          nil
        end
      end
    end
  end
end
