# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Reactions operations
    #
    # @generated from OpenAPI spec
    class ReactionsService < BaseService

      # list_for_comment operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param comment_id [String] comment id ID
      # @return [Hash] response data
      def list_for_comment(account_id:, card_number:, comment_id:)
        with_operation(service: "reactions", operation: "ListCommentReactions", is_mutation: false, resource_id: comment_id) do
          http_get("/#{account_id}/cards/#{card_number}/comments/#{comment_id}/reactions.json").json
        end
      end

      # create_for_comment operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param comment_id [String] comment id ID
      # @param content [String] content
      # @return [Hash] response data
      def create_for_comment(account_id:, card_number:, comment_id:, content:)
        with_operation(service: "reactions", operation: "CreateCommentReaction", is_mutation: true, resource_id: comment_id) do
          http_post("/#{account_id}/cards/#{card_number}/comments/#{comment_id}/reactions.json", body: compact_params(content: content)).json
        end
      end

      # delete_for_comment operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param comment_id [String] comment id ID
      # @param reaction_id [String] reaction id ID
      # @return [void]
      def delete_for_comment(account_id:, card_number:, comment_id:, reaction_id:)
        with_operation(service: "reactions", operation: "DeleteCommentReaction", is_mutation: true, resource_id: reaction_id) do
          http_delete("/#{account_id}/cards/#{card_number}/comments/#{comment_id}/reactions/#{reaction_id}")
          nil
        end
      end

      # list_for_card operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @return [Hash] response data
      def list_for_card(account_id:, card_number:)
        with_operation(service: "reactions", operation: "ListCardReactions", is_mutation: false, resource_id: card_number) do
          http_get("/#{account_id}/cards/#{card_number}/reactions.json").json
        end
      end

      # create_for_card operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param content [String] content
      # @return [Hash] response data
      def create_for_card(account_id:, card_number:, content:)
        with_operation(service: "reactions", operation: "CreateCardReaction", is_mutation: true, resource_id: card_number) do
          http_post("/#{account_id}/cards/#{card_number}/reactions.json", body: compact_params(content: content)).json
        end
      end

      # delete_for_card operation
      # @param account_id [String] account id ID
      # @param card_number [Integer] card number ID
      # @param reaction_id [String] reaction id ID
      # @return [void]
      def delete_for_card(account_id:, card_number:, reaction_id:)
        with_operation(service: "reactions", operation: "DeleteCardReaction", is_mutation: true, resource_id: reaction_id) do
          http_delete("/#{account_id}/cards/#{card_number}/reactions/#{reaction_id}")
          nil
        end
      end
    end
  end
end
