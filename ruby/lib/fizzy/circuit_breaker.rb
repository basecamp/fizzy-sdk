# frozen_string_literal: true

module Fizzy
  # Circuit breaker pattern for fault tolerance.
  #
  # Tracks consecutive failures and opens the circuit when the threshold is
  # reached, preventing further requests until the recovery timeout expires.
  #
  # States:
  # - :closed  -- normal operation, requests flow through
  # - :open    -- circuit tripped, requests fail immediately
  # - :half_open -- recovery probe, single request allowed through
  #
  # @example
  #   breaker = Fizzy::CircuitBreaker.new(threshold: 5, timeout: 30)
  #   breaker.call { http.get("/boards") }
  class CircuitBreaker
    # @param threshold [Integer] consecutive failures before opening
    # @param timeout [Numeric] seconds to wait before half-open probe
    def initialize(threshold: 5, timeout: 30)
      @threshold = threshold
      @timeout = timeout
      @failure_count = 0
      @last_failure_at = nil
      @state = :closed
      @mutex = Mutex.new
    end

    # @return [Symbol] current circuit state (:closed, :open, :half_open)
    def state
      @mutex.synchronize { effective_state }
    end

    # Executes the block through the circuit breaker.
    #
    # @yield the operation to protect
    # @return the result of the block
    # @raise [Fizzy::APIError] if circuit is open
    def call
      half_open_probe = false

      @mutex.synchronize do
        case effective_state
        when :open
          raise Fizzy::APIError.new(
            "Circuit breaker is open",
            retryable: true,
            hint: "Service appears unavailable, will retry after #{@timeout}s"
          )
        when :half_open
          half_open_probe = true
          @state = :half_open
        end
      end

      if half_open_probe
        # Single-probe: hold the probe flag so concurrent callers see :half_open
        # and block (they'll see :open until this probe completes).
        @mutex.synchronize { @state = :open }
        begin
          result = yield
          record_success
          return result
        rescue Fizzy::NetworkError, Fizzy::APIError => e
          record_failure if e.retryable?
          raise
        end
      end

      begin
        result = yield
        record_success
        result
      rescue Fizzy::NetworkError, Fizzy::APIError => e
        record_failure if e.retryable?
        raise
      end
    end

    # Resets the circuit breaker to closed state.
    def reset
      @mutex.synchronize do
        @failure_count = 0
        @last_failure_at = nil
        @state = :closed
      end
    end

    private

    def effective_state
      if @state == :open && @last_failure_at && \
         (Time.now - @last_failure_at) >= @timeout
        :half_open
      else
        @state
      end
    end

    def record_success
      @mutex.synchronize do
        @failure_count = 0
        @state = :closed
      end
    end

    def record_failure
      @mutex.synchronize do
        @failure_count += 1
        @last_failure_at = Time.now
        @state = :open if @failure_count >= @threshold
      end
    end
  end
end
