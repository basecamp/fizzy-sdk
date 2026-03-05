# frozen_string_literal: true

module Fizzy
  # Semaphore-based concurrency limiter (bulkhead pattern).
  #
  # Limits the number of concurrent operations to prevent resource exhaustion.
  # When the limit is reached, callers block until a slot becomes available
  # or the timeout expires.
  #
  # @example
  #   bulkhead = Fizzy::Bulkhead.new(max_concurrent: 10, timeout: 5)
  #   bulkhead.call { http.get("/boards") }
  class Bulkhead
    # @param max_concurrent [Integer] maximum concurrent operations
    # @param timeout [Numeric] seconds to wait for a slot (0 = fail immediately)
    def initialize(max_concurrent: 10, timeout: 5)
      @max_concurrent = max_concurrent
      @timeout = timeout
      @semaphore = Mutex.new
      @condition = ConditionVariable.new
      @current = 0
    end

    # @return [Integer] number of currently active operations
    attr_reader :current

    # Executes the block within the concurrency limit.
    #
    # @yield the operation to execute
    # @return the result of the block
    # @raise [Fizzy::APIError] if no slot is available within timeout
    def call
      acquire_slot
      begin
        yield
      ensure
        release_slot
      end
    end

    private

    def acquire_slot
      deadline = Time.now + @timeout

      @semaphore.synchronize do
        while @current >= @max_concurrent
          remaining = deadline - Time.now
          if remaining <= 0
            raise Fizzy::APIError.new(
              "Bulkhead limit reached (#{@max_concurrent} concurrent)",
              hint: "Too many concurrent requests, try again later"
            )
          end
          @condition.wait(@semaphore, remaining)
        end
        @current += 1
      end
    end

    def release_slot
      @semaphore.synchronize do
        @current -= 1
        @condition.signal
      end
    end
  end
end
