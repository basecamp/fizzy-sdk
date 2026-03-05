# frozen_string_literal: true

module Fizzy
  # Token bucket rate limiter for client-side rate limiting.
  #
  # Prevents the client from exceeding a configurable request rate,
  # avoiding 429 responses from the server.
  #
  # @example
  #   limiter = Fizzy::RateLimiter.new(rate: 10, burst: 20)
  #   limiter.acquire  # blocks until a token is available
  class RateLimiter
    # @param rate [Numeric] tokens per second (sustained rate)
    # @param burst [Integer] maximum token bucket size (burst capacity)
    def initialize(rate: 10, burst: 20)
      @rate = rate.to_f
      @burst = burst
      @tokens = burst.to_f
      @last_refill = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @mutex = Mutex.new
    end

    # Acquires a token, blocking if necessary until one is available.
    #
    # @return [void]
    def acquire
      loop do
        wait_time = nil

        @mutex.synchronize do
          refill
          if @tokens >= 1.0
            @tokens -= 1.0
            return
          else
            wait_time = (1.0 - @tokens) / @rate
          end
        end

        sleep(wait_time) if wait_time&.positive?
      end
    end

    # Attempts to acquire a token without blocking.
    #
    # @return [Boolean] true if a token was acquired
    def try_acquire
      @mutex.synchronize do
        refill
        if @tokens >= 1.0
          @tokens -= 1.0
          true
        else
          false
        end
      end
    end

    private

    def refill
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      elapsed = now - @last_refill
      @tokens = [ @tokens + elapsed * @rate, @burst.to_f ].min
      @last_refill = now
    end
  end
end
