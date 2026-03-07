# frozen_string_literal: true

module Fizzy
  # Main client for the Fizzy API.
  #
  # Client holds shared resources and provides service accessors for all
  # 15 Fizzy services. Unlike Basecamp's Client -> AccountClient pattern,
  # Fizzy does not require an account ID -- all services are available
  # directly on the Client.
  #
  # @example Basic usage
  #   config = Fizzy::Config.from_env
  #   token_provider = Fizzy::StaticTokenProvider.new(ENV["FIZZY_ACCESS_TOKEN"])
  #   client = Fizzy::Client.new(config: config, token_provider: token_provider)
  #
  #   boards = client.boards.list.to_a
  #   card = client.cards.get(board_id: 1, card_id: 42)
  #
  # @example With custom hooks
  #   require "logger"
  #   logger = Logger.new($stdout)
  #   hooks = Fizzy::LoggerHooks.new(logger)
  #
  #   client = Fizzy::Client.new(
  #     config: config,
  #     token_provider: token_provider,
  #     hooks: hooks
  #   )
  class Client
    # @return [Config] client configuration
    attr_reader :config

    # Creates a new Fizzy API client.
    #
    # @param config [Config] configuration settings
    # @param token_provider [TokenProvider, nil] token provider (deprecated, use auth_strategy)
    # @param auth_strategy [AuthStrategy, nil] authentication strategy
    # @param hooks [Hooks, nil] observability hooks
    def initialize(config:, token_provider: nil, auth_strategy: nil, hooks: nil)
      raise ArgumentError, "provide either token_provider or auth_strategy, not both" if token_provider && auth_strategy
      raise ArgumentError, "provide token_provider or auth_strategy" if !token_provider && !auth_strategy

      @config = config
      @hooks = hooks || NoopHooks.new
      @http = Http.new(config: config, token_provider: token_provider, auth_strategy: auth_strategy, hooks: @hooks)
      @services = {}
      @mutex = Mutex.new
    end

    # @api private
    # Returns the HTTP client for making requests.
    # @return [Http]
    attr_reader :http

    # @api private
    # Returns the observability hooks.
    # @return [Hooks]
    attr_reader :hooks

    # Performs a GET request.
    # @param path [String] URL path
    # @param params [Hash] query parameters
    # @return [Response]
    def get(path, params: {})
      @http.get(path, params: params)
    end

    # Performs a POST request.
    # @param path [String] URL path
    # @param body [Hash, nil] request body
    # @return [Response]
    def post(path, body: nil)
      @http.post(path, body: body)
    end

    # Performs a PUT request.
    # @param path [String] URL path
    # @param body [Hash, nil] request body
    # @return [Response]
    def put(path, body: nil)
      @http.put(path, body: body)
    end

    # Performs a PATCH request.
    # @param path [String] URL path
    # @param body [Hash, nil] request body
    # @return [Response]
    def patch(path, body: nil)
      @http.patch(path, body: body)
    end

    # Performs a DELETE request.
    # @param path [String] URL path
    # @param retryable [Boolean, nil] override retry behavior
    # @return [Response]
    def delete(path, retryable: nil)
      @http.delete(path, retryable: retryable)
    end

    # Performs a POST request with raw binary data.
    # Used for file uploads.
    # @param path [String] URL path
    # @param body [String, IO] raw binary data
    # @param content_type [String] MIME content type
    # @return [Response]
    def post_raw(path, body:, content_type:)
      @http.post_raw(path, body: body, content_type: content_type)
    end

    # Fetches all pages of a paginated resource.
    # @param path [String] URL path
    # @param params [Hash] query parameters
    # @yield [Hash] each item from the response
    # @return [Enumerator] if no block given
    def paginate(path, params: {}, &)
      @http.paginate(path, params: params, &)
    end

    # @!group Services

    # @return [Services::IdentityService]
    def identity
      service(:identity) { Services::IdentityService.new(self) }
    end

    # @return [Services::BoardsService]
    def boards
      service(:boards) { Services::BoardsService.new(self) }
    end

    # @return [Services::ColumnsService]
    def columns
      service(:columns) { Services::ColumnsService.new(self) }
    end

    # @return [Services::CardsService]
    def cards
      service(:cards) { Services::CardsService.new(self) }
    end

    # @return [Services::CommentsService]
    def comments
      service(:comments) { Services::CommentsService.new(self) }
    end

    # @return [Services::StepsService]
    def steps
      service(:steps) { Services::StepsService.new(self) }
    end

    # @return [Services::ReactionsService]
    def reactions
      service(:reactions) { Services::ReactionsService.new(self) }
    end

    # @return [Services::NotificationsService]
    def notifications
      service(:notifications) { Services::NotificationsService.new(self) }
    end

    # @return [Services::TagsService]
    def tags
      service(:tags) { Services::TagsService.new(self) }
    end

    # @return [Services::UsersService]
    def users
      service(:users) { Services::UsersService.new(self) }
    end

    # @return [Services::PinsService]
    def pins
      service(:pins) { Services::PinsService.new(self) }
    end

    # @return [Services::UploadsService]
    def uploads
      service(:uploads) { Services::UploadsService.new(self) }
    end

    # @return [Services::WebhooksService]
    def webhooks
      service(:webhooks) { Services::WebhooksService.new(self) }
    end

    # @return [Services::SessionsService]
    def sessions
      service(:sessions) { Services::SessionsService.new(self) }
    end

    # @return [Services::DevicesService]
    def devices
      service(:devices) { Services::DevicesService.new(self) }
    end

    # @!endgroup

    private

    def service(name)
      @mutex.synchronize do
        @services[name] ||= yield
      end
    end
  end
end
