# frozen_string_literal: true

module Fizzy
  # Interface for providing access tokens.
  # Implement this to provide custom token management.
  #
  # @example Static token provider
  #   token_provider = Fizzy::StaticTokenProvider.new("your-access-token")
  #   client = Fizzy::Client.new(config: config, token_provider: token_provider)
  #
  # @example Custom token provider with refresh
  #   class MyTokenProvider
  #     include Fizzy::TokenProvider
  #
  #     def access_token
  #       # Return current token, refreshing if needed
  #     end
  #
  #     def refresh
  #       # Refresh the token
  #     end
  #   end
  module TokenProvider
    # Returns the current access token.
    # @return [String] the access token
    def access_token
      raise NotImplementedError, "#{self.class} must implement #access_token"
    end

    # Refreshes the access token.
    # @return [Boolean] true if refresh succeeded
    def refresh
      false
    end

    # Returns whether token refresh is supported.
    # @return [Boolean]
    def refreshable?
      false
    end
  end
end
