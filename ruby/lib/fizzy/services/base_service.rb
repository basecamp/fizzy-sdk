# frozen_string_literal: true

require "cgi/escape"
require_relative "../errors"

module Fizzy
  module Services
    # Base service class for Fizzy API services.
    #
    # Provides shared functionality for all service classes including:
    # - HTTP method delegation (http_get, http_post, etc.)
    # - Pagination support
    # - Operation hooks (with_operation, wrap_paginated)
    #
    # @example
    #   class CardsService < BaseService
    #     def list(board_id:)
    #       paginate("/boards/#{board_id}/cards")
    #     end
    #   end
    class BaseService
      # @param client [Object] the parent client (Client)
      def initialize(client)
        @client = client
        @hooks = client.hooks
      end

      protected

      # Wraps a service operation with hooks for observability.
      # @param service [String] service name (e.g., "boards")
      # @param operation [String] operation name (e.g., "list")
      # @param resource_type [String, nil] resource type (e.g., "Board")
      # @param is_mutation [Boolean] whether this is a write operation
      # @param resource_id [Integer, String, nil] resource ID
      # @yield the operation to execute
      # @return the result of the block
      def with_operation(service:, operation:, resource_type: nil, is_mutation: false, resource_id: nil)
        info = OperationInfo.new(
          service: service, operation: operation, resource_type: resource_type,
          is_mutation: is_mutation, resource_id: resource_id
        )
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        safe_hook { @hooks.on_operation_start(info) }
        result = yield
        duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round
        safe_hook { @hooks.on_operation_end(info, OperationResult.new(duration_ms: duration, error: nil)) }
        result
      rescue => e
        duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round
        safe_hook { @hooks.on_operation_end(info, OperationResult.new(duration_ms: duration, error: e)) }
        raise
      end

      # Wraps a lazy Enumerator so operation hooks fire around actual iteration,
      # not at enumerator creation time. Hooks fire when the consumer begins
      # iterating (.each, .to_a, .first, etc.) and end fires via ensure when
      # iteration completes, errors, or is cut short by break/take.
      def wrap_paginated(service:, operation:, is_mutation: false, resource_id: nil)
        info = OperationInfo.new(
          service: service, operation: operation,
          is_mutation: is_mutation, resource_id: resource_id
        )
        enum = yield

        hooks = @hooks
        Enumerator.new do |yielder|
          start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          error = nil
          begin
            safe_hook { hooks.on_operation_start(info) }
            enum.each { |item| yielder.yield(item) }
          rescue => e
            error = e
            raise
          ensure
            duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round
            safe_hook { hooks.on_operation_end(info, OperationResult.new(duration_ms: duration, error: error)) }
          end
        end
      end

      # Invoke a hook callback, swallowing exceptions so hooks never break SDK behavior.
      def safe_hook
        yield
      rescue => e
        warn "Fizzy hook error: #{e.class}: #{e.message}"
      end

      # @return [Http] the HTTP client for direct access
      def http
        @client.http
      end

      # Helper to remove nil values from a hash.
      # @param hash [Hash] the input hash
      # @return [Hash] hash with nil values removed
      def compact_params(**kwargs)
        kwargs.compact
      end

      # Delegate HTTP methods to the client with http_ prefix to avoid conflicts
      # with service method names (e.g., service.get vs http_get)
      %i[get post put patch delete post_raw].each do |method|
        define_method(:"http_#{method}") do |*args, **kwargs, &block|
          @client.public_send(method, *args, **kwargs, &block)
        end
      end

      # Paginate doesn't conflict with service methods, keep as-is
      def paginate(...)
        @client.paginate(...)
      end
    end
  end
end
