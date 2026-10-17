# frozen_string_literal: true

module Fizzy
  # Signs in without a password. Fizzy emails a code to an address and, once the person types
  # it back, hands out a session token for {CookieAuth}.
  #
  # The two steps are one exchange as far as Fizzy is concerned: creating the session sets a
  # +pending_authentication_token+ cookie naming the address the code went to, and redeeming
  # the code has to send that cookie back or the code is refused. The flow keeps the token
  # between the calls, and hands it out for a caller that finishes in another process (a CLI
  # that prompts for the code on its next run), which picks it up again with +pending_token:+.
  #
  # Both requests go through the generated {Services::SessionsService}, so their paths and
  # bodies are the model's: +POST /session.json+ with +email_address+, then
  # +POST /session/magic_link.json+ with +code+.
  #
  # @example
  #   flow = Fizzy::MagicLinkFlow.new
  #   flow.create_session(email_address: "jane@example.com")
  #   # ... the person reads the code out of their email ...
  #   session = flow.redeem(code: "ABC123")
  #   client = Fizzy.client(auth: Fizzy::CookieAuth.new(session["session_token"]))
  #
  # @example Finishing in another process
  #   pending = Fizzy::MagicLinkFlow.new.tap { _1.create_session(email_address: email) }.pending_token
  #   # ... later ...
  #   Fizzy::MagicLinkFlow.new(pending_token: pending).redeem(code: code)
  class MagicLinkFlow
    # The cookie a pending sign-in is carried in between creating the session and redeeming
    # the code.
    PENDING_COOKIE = "pending_authentication_token"

    # The token a pending sign-in is waiting on, for a caller that finishes the flow in
    # another process.
    # @return [String, nil]
    attr_reader :pending_token

    # @param base_url [String] Fizzy API base URL
    # @param hooks [Hooks, nil] observability hooks
    # @param pending_token [String, nil] the pending token of a sign-in another flow started
    def initialize(base_url: Config::DEFAULT_BASE_URL, hooks: nil, pending_token: nil)
      @pending_token = pending_token
      @client = Client.new(
        config: Config.new(base_url: base_url),
        auth_strategy: PendingCookieAuth.new(self),
        hooks: hooks
      )
    end

    # Asks Fizzy to email a sign-in code to the address, and keeps the pending token the
    # answer carries for {#redeem}.
    #
    # @param email_address [String] the address to send the code to
    # @return [String] the pending authentication token
    # @raise [APIError] when Fizzy answers without a pending token
    def create_session(email_address:)
      answer = @client.sessions.create(email_address: email_address)
      token = answer.is_a?(Hash) ? answer["pending_authentication_token"] : nil
      raise APIError.new("Fizzy answered no pending authentication token") \
        unless token.is_a?(String) && !token.empty?

      @pending_token = token
    end

    # Redeems the code from the email, sending back the pending token as the cookie Fizzy
    # reads it from.
    #
    # @param code [String] the code from the magic-link email
    # @return [Hash] +session_token+ and +requires_signup_completion+
    # @raise [UsageError] when no sign-in is pending
    # @raise [AuthError] when Fizzy refuses the code or the pending token
    def redeem(code:)
      raise UsageError.new("no sign-in is pending; call create_session first, or pass pending_token:") \
        if @pending_token.nil? || @pending_token.empty?

      answer = @client.sessions.redeem_magic_link(code: code)
      raise APIError.new("Fizzy answered no session token") \
        unless answer.is_a?(Hash) && answer["session_token"].is_a?(String)

      answer.slice("session_token", "requires_signup_completion")
    end

    # A +Cookie+ header value carrying one cookie, its value percent-encoded as Rack decodes it.
    # @api private
    def self.cookie(name, value)
      encoded = value.to_s.b.gsub(/[^A-Za-z0-9\-_.~]/n) { |byte| format("%%%02X", byte.ord) }
      "#{name}=#{encoded}"
    end

    # Sends the flow's pending token, once there is one, as the cookie Fizzy reads the
    # pending sign-in from, and no other credentials: there are none yet.
    # @api private
    class PendingCookieAuth
      include AuthStrategy

      def initialize(flow)
        @flow = flow
      end

      def authenticate(headers)
        token = @flow.pending_token
        headers["Cookie"] = MagicLinkFlow.cookie(PENDING_COOKIE, token) unless token.nil? || token.empty?
      end
    end
  end
end
