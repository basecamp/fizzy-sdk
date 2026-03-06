# frozen_string_literal: true

module Fizzy
  module Services
    # Service for Pins operations
    #
    # @generated from OpenAPI spec
    class PinsService < BaseService

      # list operation
      # @return [Hash] response data
      def list()
        with_operation(service: "pins", operation: "ListPins", is_mutation: false) do
          http_get("/my/pins.json").json
        end
      end
    end
  end
end
