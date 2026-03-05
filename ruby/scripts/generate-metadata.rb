#!/usr/bin/env ruby
# frozen_string_literal: true

# Extracts x-fizzy-* extensions from OpenAPI spec into a runtime-accessible metadata file.
# This allows the Ruby SDK to read operation metadata at runtime for retry, pagination, etc.
#
# Usage: ruby scripts/generate-metadata.rb > lib/fizzy/generated/metadata.json

require 'json'
require 'time'

# Extract metadata from OpenAPI spec
class MetadataExtractor
  METHODS = %w[get post put patch delete].freeze

  def initialize(openapi_path)
    @openapi = JSON.parse(File.read(openapi_path))
  end

  def extract
    operations = {}

    (@openapi['paths'] || {}).each_value do |path_item|
      METHODS.each do |method|
        operation = path_item[method]
        next unless operation

        operation_id = operation['operationId']
        next unless operation_id

        metadata = extract_operation_metadata(operation)
        operations[operation_id] = metadata if metadata.any?
      end
    end

    {
      '$schema' => 'https://fizzy.do/schemas/sdk-metadata.json',
      'version' => '1.0.0',
      'generated' => Time.now.utc.iso8601,
      'operations' => operations
    }
  end

  private

  def extract_operation_metadata(operation)
    metadata = {}

    # Extract x-fizzy-retry
    if (retry_config = operation['x-fizzy-retry'])
      metadata['retry'] = {
        'maxAttempts' => retry_config['maxAttempts'],
        'baseDelayMs' => retry_config['baseDelayMs'],
        'backoff' => retry_config['backoff'],
        'retryOn' => retry_config['retryOn']
      }
    end

    # Extract x-fizzy-pagination
    if (pagination = operation['x-fizzy-pagination'])
      metadata['pagination'] = {
        'style' => pagination['style'],
        'pageParam' => pagination['pageParam'],
        'maxPageSize' => pagination['maxPageSize']
      }.compact
    end

    # Extract x-fizzy-idempotent
    if (idempotent = operation['x-fizzy-idempotent'])
      metadata['idempotent'] = {
        'keySupported' => idempotent['keySupported'],
        'keyHeader' => idempotent['keyHeader'],
        'natural' => idempotent['natural']
      }.compact
    end

    # Extract x-fizzy-sensitive
    if (sensitive = operation['x-fizzy-sensitive'])
      metadata['sensitive'] = sensitive.map do |s|
        {
          'field' => s['field'],
          'category' => s['category'],
          'redact' => s['redact']
        }.compact
      end
    end

    metadata
  end
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  openapi_path = ARGV[0] || File.expand_path('../../openapi.json', __dir__)

  unless File.exist?(openapi_path)
    warn "Error: OpenAPI file not found: #{openapi_path}"
    exit 1
  end

  extractor = MetadataExtractor.new(openapi_path)
  metadata = extractor.extract

  puts JSON.pretty_generate(metadata)
end
