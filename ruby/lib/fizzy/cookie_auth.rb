# frozen_string_literal: true

module Fizzy
  # Cookie-based authentication strategy.
  # Sets the Cookie header with the session token for session-based auth
  # (mobile/web clients).
  #
  # @example
  #   auth = Fizzy::CookieAuth.new("session_token_value")
  #   client = Fizzy.client(auth: auth)
  class CookieAuth
    include AuthStrategy

    # @param session_token [String] the session token value
    # @param cookie_name [String] the cookie name (defaults to "session_token")
    def initialize(session_token, cookie_name: "session_token")
      raise ArgumentError, "session_token cannot be nil or empty" if session_token.nil? || session_token.empty?

      @session_token = session_token
      @cookie_name = cookie_name
    end

    def authenticate(headers)
      headers["Cookie"] = "#{@cookie_name}=#{@session_token}"
    end
  end
end
