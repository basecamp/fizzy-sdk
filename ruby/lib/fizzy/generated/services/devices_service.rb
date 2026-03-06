# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Devices operations
    #
    # @generated from OpenAPI spec
    class DevicesService < BaseService

      # register operation
      # @param account_id [String] account id ID
      # @param token [String] token
      # @param platform [String] platform
      # @param name [String, nil] name
      # @return [void]
      def register(account_id:, token:, platform:, name: nil)
        with_operation(service: "devices", operation: "RegisterDevice", is_mutation: true, resource_id: account_id) do
          http_post("/#{account_id}/devices", body: compact_params(token: token, platform: platform, name: name))
          nil
        end
      end

      # unregister operation
      # @param account_id [String] account id ID
      # @param device_token [String] device token ID
      # @return [void]
      def unregister(account_id:, device_token:)
        with_operation(service: "devices", operation: "UnregisterDevice", is_mutation: true, resource_id: device_token) do
          http_delete("/#{account_id}/devices/#{device_token}")
          nil
        end
      end
    end
  end
end
