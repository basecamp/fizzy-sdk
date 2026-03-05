#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates Ruby type stubs from OpenAPI schema definitions.
#
# Usage: ruby scripts/generate-types.rb [--openapi ../openapi.json] [--output lib/fizzy/generated/types.rb]
#
# Produces a types.rb file with:
# - Struct-based domain types for each schema
# - Nested type support for composed schemas
# - Documentation from OpenAPI descriptions

require "json"
require "fileutils"

# Generates Ruby type stubs from OpenAPI schema definitions.
class TypeGenerator
  def initialize(openapi_path)
    @openapi = JSON.parse(File.read(openapi_path))
    @schemas = @openapi.dig("components", "schemas") || {}
  end

  def generate(output_path)
    FileUtils.mkdir_p(File.dirname(output_path))

    lines = []
    lines << "# frozen_string_literal: true"
    lines << ""
    lines << "# @generated from OpenAPI spec — do not edit by hand"
    lines << "#"
    lines << "# These types provide structured access to API response data."
    lines << "# Each type is a Data.define (Ruby 3.2+) with keyword initialization."
    lines << ""
    lines << "module Fizzy"
    lines << "  module Types"

    sorted_schemas.each do |name, schema|
      next if internal_schema?(name)

      type_lines = generate_type(name, schema)
      type_lines.each { |l| lines << "    #{l}" }
      lines << ""
    end

    lines << "  end"
    lines << "end"
    lines << ""

    File.write(output_path, lines.join("\n"))
    puts "Generated #{output_path} (#{sorted_schemas.count { |n, _| !internal_schema?(n) }} types)"
  end

  private

  def sorted_schemas
    @schemas.sort_by { |name, _| name }
  end

  def internal_schema?(name)
    name.end_with?("Input", "Request") || name.start_with?("__")
  end

  def generate_type(name, schema)
    lines = []
    properties = schema["properties"] || {}
    required_fields = schema["required"] || []
    description = schema["description"]

    lines << "# #{description}" if description
    lines << "# @generated"

    fields = properties.map do |field_name, field_schema|
      ruby_name = to_snake_case(field_name)
      ruby_type = schema_to_ruby_type(field_schema)
      required = required_fields.include?(field_name)
      { name: ruby_name, json_name: field_name, type: ruby_type, required: required, \
        description: field_schema["description"] }
    end

    if fields.empty?
      lines << "#{name} = Data.define"
      return lines
    end

    field_names = fields.map { |f| ":#{f[:name]}" }.join(", ")
    lines << "#{name} = Data.define(#{field_names}) do"

    lines << "  # @param data [Hash] raw JSON response"
    lines << "  def self.from_json(data)"
    lines << "    new("

    fields.each_with_index do |f, i|
      comma = i < fields.length - 1 ? "," : ""
      accessor = "data[\"#{f[:json_name]}\"]"
      lines << "      #{f[:name]}: #{accessor}#{comma}"
    end

    lines << "    )"
    lines << "  end"
    lines << "end"

    lines
  end

  def schema_to_ruby_type(schema)
    return "Object" unless schema

    if schema["$ref"]
      ref_name = schema["$ref"].split("/").last
      return ref_name
    end

    case schema["type"]
    when "integer" then "Integer"
    when "number" then "Float"
    when "boolean" then "Boolean"
    when "array"
      item_type = schema_to_ruby_type(schema["items"])
      "Array<#{item_type}>"
    when "object" then "Hash"
    else "String"
    end
  end

  def to_snake_case(str)
    str.gsub(/([a-z\d])([A-Z])/, '\1_\2')
       .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
       .downcase
  end
end

if __FILE__ == $PROGRAM_NAME
  openapi_path = nil
  output_path = nil

  i = 0
  while i < ARGV.length
    case ARGV[i]
    when "--openapi"
      openapi_path = ARGV[i + 1]
      i += 2
    when "--output"
      output_path = ARGV[i + 1]
      i += 2
    else
      i += 1
    end
  end

  openapi_path ||= File.expand_path("../../openapi.json", __dir__)
  output_path ||= File.expand_path("../lib/fizzy/generated/types.rb", __dir__)

  unless File.exist?(openapi_path)
    warn "Error: OpenAPI file not found: #{openapi_path}"
    exit 1
  end

  generator = TypeGenerator.new(openapi_path)
  generator.generate(output_path)
end
