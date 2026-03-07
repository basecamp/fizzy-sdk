# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Comments operations
    #
    # @generated from OpenAPI spec
    class CommentsService < BaseService

      # list operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [Enumerator<Hash>] paginated results
      def list(account_id:, card_number:)
        wrap_paginated(service: "comments", operation: "ListComments", is_mutation: false, resource_id: card_number) do
          paginate("/#{account_id}/cards/#{card_number}/comments.json")
        end
      end

      # create operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param body [String] body
      # @param created_at [String, nil] created at
      # @return [Hash] response data
      def create(account_id:, card_number:, body:, created_at: nil)
        with_operation(service: "comments", operation: "CreateComment", is_mutation: true, resource_id: card_number) do
          http_post("/#{account_id}/cards/#{card_number}/comments.json", body: compact_params(body: body, created_at: created_at)).json
        end
      end

      # get operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param comment_id [String] comment id ID
      # @return [Hash] response data
      def get(account_id:, card_number:, comment_id:)
        with_operation(service: "comments", operation: "GetComment", is_mutation: false, resource_id: comment_id) do
          http_get("/#{account_id}/cards/#{card_number}/comments/#{comment_id}").json
        end
      end

      # update operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param comment_id [String] comment id ID
      # @param body [String] body
      # @return [Hash] response data
      def update(account_id:, card_number:, comment_id:, body:)
        with_operation(service: "comments", operation: "UpdateComment", is_mutation: true, resource_id: comment_id) do
          http_patch("/#{account_id}/cards/#{card_number}/comments/#{comment_id}", body: compact_params(body: body)).json
        end
      end

      # delete operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param comment_id [String] comment id ID
      # @return [void]
      def delete(account_id:, card_number:, comment_id:)
        with_operation(service: "comments", operation: "DeleteComment", is_mutation: true, resource_id: comment_id) do
          http_delete("/#{account_id}/cards/#{card_number}/comments/#{comment_id}")
          nil
        end
      end
    end
  end
end
