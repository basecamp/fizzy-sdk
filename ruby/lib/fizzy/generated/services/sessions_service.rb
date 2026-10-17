# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Sessions operations
    #
    # @generated from OpenAPI spec
    class SessionsService < BaseService

      # Starts a magic-link sign-in and answers the pending authentication token.
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

      # Redeems the code from a magic-link email for a session token.
      # @param code [String] The code from the magic-link email.
      # @return [Hash] response data
      def redeem_magic_link(code:)
        with_operation(service: "sessions", operation: "RedeemMagicLink", is_mutation: true) do
          http_post("/session/magic_link.json", body: compact_params(code: code)).json
        end
      end

      # complete_signup operation
      # @param full_name [String] full name
      # @return [void]
      def complete_signup(full_name:)
        with_operation(service: "sessions", operation: "CompleteSignup", is_mutation: true) do
          http_post("/signup/completion.json", body: compact_params(full_name: full_name))
          nil
        end
      end

      # complete_join operation
      # @param name [String] name
      # @return [void]
      def complete_join(name:)
        with_operation(service: "sessions", operation: "CompleteJoin", is_mutation: true) do
          http_post("/users/joins.json", body: compact_params(name: name))
          nil
        end
      end
    end
  end
end
