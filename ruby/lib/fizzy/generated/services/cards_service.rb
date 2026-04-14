# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Cards operations
    #
    # @generated from OpenAPI spec
    class CardsService < BaseService

      # list_activities operation
      # @param account_id [String] account id ID
      # @param creator_ids [Array, nil] creator ids
      # @param board_ids [Array, nil] board ids
      # @return [Enumerator<Hash>] paginated results
      def list_activities(account_id:, creator_ids: nil, board_ids: nil)
        wrap_paginated(service: "cards", operation: "ListActivities", is_mutation: false, resource_id: account_id) do
          params = compact_params(creator_ids: creator_ids, board_ids: board_ids)
          paginate("/#{account_id}/activities.json", params: params)
        end
      end

      # list_closed_cards operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @return [Enumerator<Hash>] paginated results
      def list_closed_cards(account_id:, board_id:)
        wrap_paginated(service: "cards", operation: "ListClosedCards", is_mutation: false, resource_id: board_id) do
          paginate("/#{account_id}/boards/#{board_id}/columns/closed.json")
        end
      end

      # list_postponed_cards operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @return [Enumerator<Hash>] paginated results
      def list_postponed_cards(account_id:, board_id:)
        wrap_paginated(service: "cards", operation: "ListPostponedCards", is_mutation: false, resource_id: board_id) do
          paginate("/#{account_id}/boards/#{board_id}/columns/not_now.json")
        end
      end

      # list_stream_cards operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @return [Enumerator<Hash>] paginated results
      def list_stream_cards(account_id:, board_id:)
        wrap_paginated(service: "cards", operation: "ListStreamCards", is_mutation: false, resource_id: board_id) do
          paginate("/#{account_id}/boards/#{board_id}/columns/stream.json")
        end
      end

      # list_column_cards operation
      # @param account_id [String] account id ID
      # @param board_id [String] board id ID
      # @param column_id [String] column id ID
      # @return [Enumerator<Hash>] paginated results
      def list_column_cards(account_id:, board_id:, column_id:)
        wrap_paginated(service: "cards", operation: "ListColumnCards", is_mutation: false, resource_id: column_id) do
          paginate("/#{account_id}/boards/#{board_id}/columns/#{column_id}/cards.json")
        end
      end

      # list operation
      # @param account_id [String] account id ID
      # @param board_ids [Array, nil] board ids
      # @param tag_ids [Array, nil] tag ids
      # @param assignee_ids [Array, nil] assignee ids
      # @param creator_ids [Array, nil] creator ids
      # @param closer_ids [Array, nil] closer ids
      # @param card_ids [Array, nil] card ids
      # @param indexed_by [String, nil] indexed by
      # @param sorted_by [String, nil] sorted by
      # @param assignment_status [String, nil] assignment status
      # @param creation [String, nil] creation
      # @param closure [String, nil] closure
      # @param terms [Array, nil] terms
      # @return [Enumerator<Hash>] paginated results
      def list(account_id:, board_ids: nil, tag_ids: nil, assignee_ids: nil, creator_ids: nil, closer_ids: nil, card_ids: nil, indexed_by: nil, sorted_by: nil, assignment_status: nil, creation: nil, closure: nil, terms: nil)
        wrap_paginated(service: "cards", operation: "ListCards", is_mutation: false, resource_id: account_id) do
          params = compact_params(board_ids: board_ids, tag_ids: tag_ids, assignee_ids: assignee_ids, creator_ids: creator_ids, closer_ids: closer_ids, card_ids: card_ids, indexed_by: indexed_by, sorted_by: sorted_by, assignment_status: assignment_status, creation: creation, closure: closure, terms: terms)
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
          http_post("/#{account_id}/cards/#{card_number}/closure.json", retryable: true)
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
          http_post("/#{account_id}/cards/#{card_number}/goldness.json", retryable: true)
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
          http_post("/#{account_id}/cards/#{card_number}/not_now.json", retryable: true)
          nil
        end
      end

      # pin operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def pin(account_id:, card_number:)
        with_operation(service: "cards", operation: "PinCard", is_mutation: true, resource_id: card_number) do
          http_post("/#{account_id}/cards/#{card_number}/pin.json", retryable: true)
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

      # publish_card operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [void]
      def publish_card(account_id:, card_number:)
        with_operation(service: "cards", operation: "PublishCard", is_mutation: true, resource_id: card_number) do
          http_post("/#{account_id}/cards/#{card_number}/publish.json")
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
          http_post("/#{account_id}/cards/#{card_number}/triage.json", body: compact_params(column_id: column_id), retryable: true)
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
          http_post("/#{account_id}/cards/#{card_number}/watch.json", retryable: true)
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

      # search_cards operation
      # @param account_id [String] account id ID
      # @param q [String] q
      # @return [Enumerator<Hash>] paginated results
      def search_cards(account_id:, q:)
        wrap_paginated(service: "cards", operation: "SearchCards", is_mutation: false, resource_id: account_id) do
          params = compact_params(q: q)
          paginate("/#{account_id}/search.json", params: params)
        end
      end
    end
  end
end
