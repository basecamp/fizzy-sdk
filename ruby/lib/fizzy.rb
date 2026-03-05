# frozen_string_literal: true

require "zeitwerk"

# Set up Zeitwerk loader
loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)

# Ignore hand-written services - we use generated services instead (spec-conformant)
# EXCEPT: base_service.rb (infrastructure)
loader.ignore("#{__dir__}/fizzy/services")

# Collapse the generated directory so Fizzy::Generated::Services becomes Fizzy::Services
loader.collapse("#{__dir__}/fizzy/generated")

# Ignore errors.rb - it defines multiple classes, loaded explicitly below
loader.ignore("#{__dir__}/fizzy/errors.rb")
# Ignore auth_strategy.rb - defines both AuthStrategy and BearerAuth
loader.ignore("#{__dir__}/fizzy/auth_strategy.rb")
# Ignore operation_info.rb - defines both OperationInfo and OperationResult
loader.ignore("#{__dir__}/fizzy/operation_info.rb")
loader.setup

# Load infrastructure that generated services depend on
require_relative "fizzy/errors"
require_relative "fizzy/auth_strategy"
require_relative "fizzy/operation_info"
require_relative "fizzy/services/base_service"

# Load generated types if available
begin
  require_relative "fizzy/generated/types"
rescue LoadError
  # Generated types not available yet
end

# Main entry point for the Fizzy SDK.
#
# The SDK follows a Client pattern:
# - Client: Holds shared resources (HTTP client, auth strategy, hooks)
# - Provides service accessors for all 15 Fizzy services
#
# @example Basic usage
#   client = Fizzy.client(access_token: ENV["FIZZY_ACCESS_TOKEN"])
#   boards = client.boards.list.to_a
#
# @example With hooks for logging
#   class MyHooks
#     include Fizzy::Hooks
#
#     def on_request_start(info)
#       puts "Starting #{info.method} #{info.url}"
#     end
#
#     def on_request_end(info, result)
#       puts "Completed in #{result.duration}s"
#     end
#   end
#
#   client = Fizzy.client(access_token: token, hooks: MyHooks.new)
module Fizzy
  # Creates a new Fizzy client.
  #
  # This is a convenience method that creates a Client with the given options.
  #
  # @param access_token [String, nil] API access token
  # @param auth [AuthStrategy, nil] custom authentication strategy
  # @param base_url [String] Base URL for API requests
  # @param hooks [Hooks, nil] Observability hooks
  # @return [Client]
  #
  # @example With access token
  #   client = Fizzy.client(access_token: "abc123")
  #   boards = client.boards.list.to_a
  #
  # @example With custom auth strategy
  #   client = Fizzy.client(auth: Fizzy::CookieAuth.new("session_value"))
  def self.client(
    access_token: nil,
    auth: nil,
    base_url: Config::DEFAULT_BASE_URL,
    hooks: nil
  )
    raise ArgumentError, "provide either access_token or auth, not both" if access_token && auth
    raise ArgumentError, "provide access_token or auth" if !access_token && !auth

    config = Config.new(base_url: base_url)

    if auth
      Client.new(config: config, auth_strategy: auth, hooks: hooks)
    else
      token_provider = StaticTokenProvider.new(access_token)
      Client.new(config: config, token_provider: token_provider, hooks: hooks)
    end
  end
end
