# frozen_string_literal: true

module Fizzy
  # A simple token provider that returns a static access token.
  # Useful for testing or when you manage token refresh externally.
  #
  # @example
  #   provider = Fizzy::StaticTokenProvider.new(ENV["FIZZY_ACCESS_TOKEN"])
  class StaticTokenProvider
    include TokenProvider

    # @param token [String] the static access token
    def initialize(token)
      raise ArgumentError, "token cannot be nil or empty" if token.nil? || token.empty?

      @token = token
    end

    # @return [String] the access token
    def access_token
      @token
    end
  end
end
