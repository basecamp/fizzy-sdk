# frozen_string_literal: true

module Fizzy
  # Configuration container for resilience patterns.
  #
  # Bundles circuit breaker, bulkhead, and rate limiter settings
  # into a single configuration object.
  #
  # @example
  #   resilience = Fizzy::ResilienceConfig.new(
  #     circuit_breaker: { threshold: 5, timeout: 30 },
  #     bulkhead: { max_concurrent: 10, timeout: 5 },
  #     rate_limiter: { rate: 10, burst: 20 }
  #   )
  class ResilienceConfig
    # @return [CircuitBreaker, nil]
    attr_reader :circuit_breaker

    # @return [Bulkhead, nil]
    attr_reader :bulkhead

    # @return [RateLimiter, nil]
    attr_reader :rate_limiter

    # @param circuit_breaker [Hash, nil] CircuitBreaker options
    # @param bulkhead [Hash, nil] Bulkhead options
    # @param rate_limiter [Hash, nil] RateLimiter options
    def initialize(circuit_breaker: nil, bulkhead: nil, rate_limiter: nil)
      @circuit_breaker = circuit_breaker ? CircuitBreaker.new(**circuit_breaker) : nil
      @bulkhead = bulkhead ? Bulkhead.new(**bulkhead) : nil
      @rate_limiter = rate_limiter ? RateLimiter.new(**rate_limiter) : nil
    end

    # Wraps a block with all configured resilience patterns.
    #
    # Execution order: rate_limiter -> bulkhead -> circuit_breaker -> block
    #
    # @yield the operation to protect
    # @return the result of the block
    def call(&block)
      block = wrap_with_circuit_breaker(block) if @circuit_breaker
      block = wrap_with_bulkhead(block) if @bulkhead
      @rate_limiter&.acquire
      block.call
    end

    private

    def wrap_with_circuit_breaker(block)
      breaker = @circuit_breaker
      -> { breaker.call(&block) }
    end

    def wrap_with_bulkhead(block)
      bh = @bulkhead
      -> { bh.call(&block) }
    end
  end
end
