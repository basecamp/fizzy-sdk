# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Sessions operations
    #
    # @generated from OpenAPI spec
    class SessionsService < BaseService

      # create operation
      # @param email_address [String] email address
      # @return [Hash] response data
      def create(email_address:)
        with_operation(service: "sessions", operation: "CreateSession", is_mutation: true) do
          http_post("/session.json", body: compact_params(email_address: email_address)).json
        end
      end

      # destroy operation
      # @return [void]
      def destroy()
        with_operation(service: "sessions", operation: "DestroySession", is_mutation: true) do
          http_delete("/session.json", retryable: false)
          nil
        end
      end

      # redeem_magic_link operation
      # @param token [String] token
      # @return [Hash] response data
      def redeem_magic_link(token:)
        with_operation(service: "sessions", operation: "RedeemMagicLink", is_mutation: true) do
          http_post("/session/magic_link.json", body: compact_params(token: token)).json
        end
      end

      # complete_signup operation
      # @param name [String] name
      # @return [Hash] response data
      def complete_signup(name:)
        with_operation(service: "sessions", operation: "CompleteSignup", is_mutation: true) do
          http_post("/signup/completion.json", body: compact_params(name: name)).json
        end
      end
    end
  end
end
