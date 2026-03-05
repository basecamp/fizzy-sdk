# frozen_string_literal: true

module Fizzy
  # Orchestrates the passwordless magic link authentication flow.
  #
  # The flow works in two steps:
  # 1. Call CreateSession with an email address - this sends a magic link email
  # 2. Call RedeemMagicLink with the token from the magic link URL
  #
  # After redemption, the response contains a session token that can be used
  # with CookieAuth or BearerAuth for subsequent requests.
  #
  # @example
  #   flow = Fizzy::MagicLinkFlow.new(base_url: "https://fizzy.do")
  #   flow.request_magic_link(email: "user@example.com")
  #   # User clicks magic link in email, your app extracts the token
  #   session = flow.redeem(token: "magic-link-token-from-url")
  #   # Use session token for authenticated requests
  #   client = Fizzy.client(auth: Fizzy::CookieAuth.new(session["session_token"]))
  class MagicLinkFlow
    # @param base_url [String] Fizzy API base URL
    # @param hooks [Hooks, nil] observability hooks
    def initialize(base_url: Config::DEFAULT_BASE_URL, hooks: nil)
      @config = Config.new(base_url: base_url)
      @hooks = hooks || NoopHooks.new
      @http = Http.new(config: @config, auth_strategy: NullAuth.new, hooks: @hooks)
    end

    # Step 1: Request a magic link email.
    #
    # @param email [String] the user's email address
    # @return [Hash] response from the API
    def request_magic_link(email:)
      response = @http.post("/sessions", body: { email: email })
      response.json
    end

    # Step 2: Redeem a magic link token to get a session.
    #
    # @param token [String] the magic link token from the URL
    # @return [Hash] response containing session_token and user info
    def redeem(token:)
      response = @http.post("/sessions/redeem", body: { token: token })
      response.json
    end

    # Null authentication strategy for unauthenticated requests.
    # @api private
    class NullAuth
      include AuthStrategy

      def authenticate(headers)
        # No authentication needed for magic link flow initiation
      end
    end
  end
end
