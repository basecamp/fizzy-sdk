# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Uploads operations
    #
    # @generated from OpenAPI spec
    class UploadsService < BaseService

      # create_direct operation
      # @param account_id [String] account id ID
      # @param filename [String] filename
      # @param content_type [String] content type
      # @param byte_size [Integer] byte size
      # @param checksum [String] checksum
      # @return [Hash] response data
      def create_direct(account_id:, filename:, content_type:, byte_size:, checksum:)
        with_operation(service: "uploads", operation: "CreateDirectUpload", is_mutation: true, resource_id: account_id) do
          http_post("/#{account_id}/rails/active_storage/direct_uploads", body: compact_params(filename: filename, content_type: content_type, byte_size: byte_size, checksum: checksum)).json
        end
      end
    end
  end
end
