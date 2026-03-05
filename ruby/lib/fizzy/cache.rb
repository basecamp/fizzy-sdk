# frozen_string_literal: true

require "digest"
require "json"
require "fileutils"

module Fizzy
  # ETag-based HTTP cache for GET requests (file-based, opt-in).
  #
  # Stores responses keyed by URL with ETag validation. On cache hit with
  # matching ETag, returns 304 Not Modified without re-downloading the body.
  #
  # @example
  #   cache = Fizzy::Cache.new(dir: "/tmp/fizzy-cache")
  #   # Used internally by Http when cache is configured
  class Cache
    # @param dir [String] directory for cache files
    # @param max_entries [Integer] maximum cache entries before eviction
    def initialize(dir:, max_entries: 1000)
      @dir = dir
      @max_entries = max_entries
      FileUtils.mkdir_p(@dir)
    end

    # Returns cached response headers for conditional request.
    # @param url [String] the request URL
    # @return [Hash, nil] headers with If-None-Match if cached
    def conditional_headers(url)
      entry = read_entry(url)
      return nil unless entry

      { "If-None-Match" => entry["etag"] }
    end

    # Stores a response in the cache.
    # @param url [String] the request URL
    # @param etag [String] the ETag header value
    # @param body [String] the response body
    def store(url, etag:, body:)
      return if etag.nil? || etag.empty?

      evict_if_full

      entry = {
        "etag" => etag,
        "body" => body,
        "cached_at" => Time.now.to_i
      }

      path = entry_path(url)
      File.write(path, JSON.generate(entry))
    end

    # Returns cached body if available.
    # @param url [String] the request URL
    # @return [String, nil] the cached body
    def get(url)
      entry = read_entry(url)
      entry&.dig("body")
    end

    # Invalidates a cache entry.
    # @param url [String] the request URL
    def invalidate(url)
      path = entry_path(url)
      File.delete(path) if File.exist?(path)
    end

    # Clears the entire cache.
    def clear
      Dir.glob(File.join(@dir, "*.json")).each { |f| File.delete(f) }
    end

    private

    def entry_path(url)
      key = Digest::SHA256.hexdigest(url)
      File.join(@dir, "#{key}.json")
    end

    def read_entry(url)
      path = entry_path(url)
      return nil unless File.exist?(path)

      JSON.parse(File.read(path))
    rescue JSON::ParserError
      File.delete(path)
      nil
    end

    def evict_if_full
      entries = Dir.glob(File.join(@dir, "*.json"))
      return if entries.length < @max_entries

      # Evict oldest entries (by mtime)
      entries.sort_by { |f| File.mtime(f) }
             .first(entries.length - @max_entries + 1)
             .each { |f| File.delete(f) }
    end
  end
end
