#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates Ruby service classes from OpenAPI spec.
#
# Usage: ruby scripts/generate-services.rb [--openapi ../openapi.json] [--output lib/fizzy/generated/services]
#
# This generator:
# 1. Parses openapi.json
# 2. Groups operations by tag
# 3. Maps operationIds to method names
# 4. Generates Ruby service files

require 'json'
require 'fileutils'

# Service generator for Ruby SDK
class ServiceGenerator
  METHODS = %w[get post put patch delete].freeze

  # Schema reference cache for resolving $ref
  attr_reader :schemas

  # Tag to service name mapping for Fizzy's 15 services
  TAG_TO_SERVICE = {
    'Identity' => 'Identity',
    'Boards' => 'Boards',
    'Columns' => 'Columns',
    'Cards' => 'Cards',
    'Comments' => 'Comments',
    'Steps' => 'Steps',
    'Reactions' => 'Reactions',
    'Notifications' => 'Notifications',
    'Tags' => 'Tags',
    'Users' => 'Users',
    'Pins' => 'Pins',
    'Uploads' => 'Uploads',
    'Webhooks' => 'Webhooks',
    'Sessions' => 'Sessions',
    'Devices' => 'Devices',
    'Untagged' => 'Miscellaneous'
  }.freeze

  # Method name overrides for Fizzy operations
  METHOD_NAME_OVERRIDES = {
    'GetMyIdentity' => 'me',
    'ListCardReactions' => 'list_for_card',
    'CreateCardReaction' => 'create_for_card',
    'DeleteCardReaction' => 'delete_for_card',
    'ListCommentReactions' => 'list_for_comment',
    'CreateCommentReaction' => 'create_for_comment',
    'DeleteCommentReaction' => 'delete_for_comment',
    'ReadNotification' => 'read',
    'UnreadNotification' => 'unread',
    'BulkReadNotifications' => 'bulk_read',
    'GetNotificationTray' => 'tray',
    'CreateDirectUpload' => 'create_direct',
    'ActivateWebhook' => 'activate',
    'CreateSession' => 'create',
    'RedeemMagicLink' => 'redeem_magic_link',
    'DestroySession' => 'destroy',
    'CompleteSignup' => 'complete_signup',
    'RegisterDevice' => 'register',
    'UnregisterDevice' => 'unregister',
    'CloseCard' => 'close',
    'ReopenCard' => 'reopen',
    'PostponeCard' => 'postpone',
    'TriageCard' => 'triage',
    'UnTriageCard' => 'untriage',
    'GoldCard' => 'gold',
    'UngoldCard' => 'ungold',
    'AssignCard' => 'assign',
    'SelfAssignCard' => 'self_assign',
    'TagCard' => 'tag',
    'WatchCard' => 'watch',
    'UnwatchCard' => 'unwatch',
    'PinCard' => 'pin',
    'UnpinCard' => 'unpin',
    'MoveCard' => 'move',
    'DeleteCardImage' => 'delete_image',
    'DeactivateUser' => 'deactivate'
  }.freeze

  # Verb patterns for extracting method names
  VERB_PATTERNS = [
    { prefix: 'List', method: 'list' },
    { prefix: 'Get', method: 'get' },
    { prefix: 'Create', method: 'create' },
    { prefix: 'Update', method: 'update' },
    { prefix: 'Delete', method: 'delete' },
    { prefix: 'Close', method: 'close' },
    { prefix: 'Reopen', method: 'reopen' },
    { prefix: 'Postpone', method: 'postpone' },
    { prefix: 'Triage', method: 'triage' },
    { prefix: 'Assign', method: 'assign' },
    { prefix: 'Watch', method: 'watch' },
    { prefix: 'Unwatch', method: 'unwatch' },
    { prefix: 'Pin', method: 'pin' },
    { prefix: 'Unpin', method: 'unpin' },
    { prefix: 'Move', method: 'move' },
    { prefix: 'Tag', method: 'tag' },
    { prefix: 'Read', method: 'read' },
    { prefix: 'Unread', method: 'unread' },
    { prefix: 'Activate', method: 'activate' },
    { prefix: 'Deactivate', method: 'deactivate' },
    { prefix: 'Register', method: 'register' },
    { prefix: 'Unregister', method: 'unregister' },
    { prefix: 'Redeem', method: 'redeem' },
    { prefix: 'Destroy', method: 'destroy' },
    { prefix: 'Complete', method: 'complete' },
    { prefix: 'Self', method: 'self' },
    { prefix: 'Gold', method: 'gold' },
    { prefix: 'Ungold', method: 'ungold' },
    { prefix: 'Bulk', method: 'bulk' }
  ].freeze

  SIMPLE_RESOURCES = %w[
    board boards column columns card cards comment comments step steps
    reaction reactions notification notifications tag tags user users
    pin pins upload uploads webhook webhooks session sessions device devices
    identity cardimage directupload magiclink signup
  ].freeze

  def initialize(openapi_path)
    @openapi = JSON.parse(File.read(openapi_path))
    @schemas = @openapi.dig('components', 'schemas') || {}
  end

  def generate(output_dir)
    FileUtils.mkdir_p(output_dir)

    services = group_operations
    generated_files = []

    services.each do |name, service|
      code = generate_service(service)
      filename = "#{to_snake_case(name)}_service.rb"
      filepath = File.join(output_dir, filename)
      File.write(filepath, code)
      generated_files << filename
      puts "Generated #{filename} (#{service[:operations].length} operations)"
    end

    puts "\nGenerated #{services.length} services with " \
         "#{services.values.sum { |s| s[:operations].length }} operations total."
    generated_files
  end

  private

  def group_operations
    services = {}

    @openapi['paths'].each do |path, path_item|
      METHODS.each do |method|
        operation = path_item[method]
        next unless operation

        tag = operation['tags']&.first || 'Untagged'
        parsed = parse_operation(path, method, operation)

        service_name = TAG_TO_SERVICE[tag] || tag.gsub(/\s+/, '')

        services[service_name] ||= {
          name: service_name,
          class_name: "#{service_name}Service",
          description: "Service for #{service_name} operations",
          operations: []
        }

        services[service_name][:operations] << parsed
      end
    end

    services
  end

  def parse_operation(path, method, operation)
    operation_id = operation['operationId']
    method_name = extract_method_name(operation_id)
    http_method = method.upcase
    description = operation['description']&.lines&.first&.strip || "#{method_name} operation"

    # Extract path parameters
    path_params = (operation['parameters'] || [])
                  .select { |p| p['in'] == 'path' }
                  .map { |p| { name: p['name'], type: schema_to_ruby_type(p['schema']), description: p['description'] } }

    # Extract query parameters
    query_params = (operation['parameters'] || [])
                   .select { |p| p['in'] == 'query' }
                   .map do |p|
      {
        name: p['name'],
        type: schema_to_ruby_type(p['schema']),
        required: p['required'] || false,
        description: p['description']
      }
    end

    # Check for request body (JSON or binary)
    body_schema_ref = operation.dig('requestBody', 'content', 'application/json', 'schema')
    has_binary_body = operation.dig('requestBody', 'content', 'application/octet-stream', 'schema')

    # Extract body parameters from schema
    body_params = extract_body_params(body_schema_ref)

    # Check response
    success_response = operation.dig('responses', '200') || operation.dig('responses', '201')
    response_schema = success_response&.dig('content', 'application/json', 'schema')
    returns_void = response_schema.nil?
    returns_array = response_schema&.dig('type') == 'array'

    {
      operation_id: operation_id,
      method_name: method_name,
      http_method: http_method,
      path: convert_path(path),
      description: description,
      path_params: path_params,
      query_params: query_params,
      body_params: body_params,
      has_body: body_params.any?,
      has_binary_body: !!has_binary_body,
      returns_void: returns_void,
      returns_array: returns_array,
      is_mutation: http_method != 'GET',
      has_pagination: !!operation['x-fizzy-pagination']
    }
  end

  # Extract body parameters from a schema reference
  def extract_body_params(schema_ref)
    return [] unless schema_ref

    # Resolve $ref
    schema = resolve_schema_ref(schema_ref)
    return [] unless schema && schema['properties']

    required_fields = schema['required'] || []

    schema['properties'].map do |name, prop|
      type = schema_to_ruby_type(prop)
      format_hint = extract_format_hint(prop)
      {
        name: name,
        type: type,
        required: required_fields.include?(name),
        description: prop['description'],
        format_hint: format_hint
      }
    end
  end

  # Resolve a schema reference to its definition
  def resolve_schema_ref(schema_or_ref)
    return schema_or_ref unless schema_or_ref['$ref']

    ref_path = schema_or_ref['$ref']
    if ref_path.start_with?('#/components/schemas/')
      schema_name = ref_path.split('/').last
      @schemas[schema_name]
    end
  end

  # Extract format hint for documentation
  def extract_format_hint(prop)
    return nil unless prop

    case prop['format']
    when 'date'
      'YYYY-MM-DD'
    when 'date-time'
      'RFC3339 (e.g., 2024-12-15T09:00:00Z)'
    end
  end

  def extract_method_name(operation_id)
    return METHOD_NAME_OVERRIDES[operation_id] if METHOD_NAME_OVERRIDES.key?(operation_id)

    VERB_PATTERNS.each do |pattern|
      if operation_id.start_with?(pattern[:prefix])
        remainder = operation_id[pattern[:prefix].length..]
        return pattern[:method] if remainder.empty?

        resource = to_snake_case(remainder)
        return pattern[:method] if simple_resource?(resource)

        return "#{pattern[:method]}_#{resource}"
      end
    end

    to_snake_case(operation_id)
  end

  def simple_resource?(resource)
    SIMPLE_RESOURCES.include?(resource.downcase.gsub('_', ''))
  end

  def convert_path(path)
    # Convert {camelCaseParam} to #{snake_case_param}
    path.gsub(/\{(\w+)\}/) do |_match|
      param = ::Regexp.last_match(1)
      snake_param = to_snake_case(param)
      "\#{#{snake_param}}"
    end
  end

  def schema_to_ruby_type(schema)
    return 'Object' unless schema

    case schema['type']
    when 'integer' then 'Integer'
    when 'boolean' then 'Boolean'
    when 'array' then 'Array'
    else 'String'
    end
  end

  def to_snake_case(str)
    str.gsub(/([a-z\d])([A-Z])/, '\1_\2')
       .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
       .downcase
  end

  def generate_service(service)
    lines = []

    # Check if any operation uses URI encoding (binary uploads with query params)
    needs_uri = service[:operations].any? { |op| op[:has_binary_body] && op[:query_params].any? }

    lines << '# frozen_string_literal: true'
    lines << ''
    lines << 'require "uri"' if needs_uri
    lines << '' if needs_uri
    lines << 'module Fizzy'
    lines << '  module Services'
    lines << "    # #{service[:description]}"
    lines << '    #'
    lines << '    # @generated from OpenAPI spec'
    lines << "    class #{service[:class_name]} < BaseService"

    service[:operations].each do |op|
      lines << ''
      lines.concat(generate_method(op, service_name: service[:name]))
    end

    lines << '    end'
    lines << '  end'
    lines << 'end'
    lines << ''

    lines.join("\n")
  end

  def generate_method(op, service_name:)
    lines = []

    # Method signature
    params = build_params(op)

    # YARD documentation
    lines << "      # #{op[:description]}"

    # Add @param tags for path params
    op[:path_params].each do |p|
      ruby_name = to_snake_case(p[:name])
      type = p[:type] || 'Integer'
      desc = p[:description] || "#{ruby_name.gsub('_', ' ')} ID"
      lines << "      # @param #{ruby_name} [#{type}] #{desc}"
    end

    # Add @param tags for binary upload params
    if op[:has_binary_body]
      lines << '      # @param data [String] Binary file data to upload'
      lines << '      # @param content_type [String] MIME type of the file'
    end

    # Add @param tags for body params
    if op[:body_params]&.any?
      op[:body_params].each do |b|
        ruby_name = to_snake_case(b[:name])
        type = b[:type] || 'Object'
        type = "#{type}, nil" unless b[:required]
        desc = b[:description] || ruby_name.gsub('_', ' ')
        format_hint = b[:format_hint] ? " (#{b[:format_hint]})" : ''
        lines << "      # @param #{ruby_name} [#{type}] #{desc}#{format_hint}"
      end
    end

    # Add @param tags for query params
    op[:query_params].each do |q|
      ruby_name = to_snake_case(q[:name])
      type = q[:type] || 'String'
      type = "#{type}, nil" unless q[:required]
      desc = q[:description] || ruby_name.gsub('_', ' ')
      lines << "      # @param #{ruby_name} [#{type}] #{desc}"
    end

    # Add @return tag
    if op[:returns_void]
      lines << '      # @return [void]'
    elsif op[:returns_array] || op[:has_pagination]
      lines << '      # @return [Enumerator<Hash>] paginated results'
    else
      lines << '      # @return [Hash] response data'
    end

    lines << "      def #{op[:method_name]}(#{params})"

    # Build the path
    path_expr = build_path_expression(op)

    is_paginated = op[:returns_array] || op[:has_pagination]
    hook_kwargs = build_hook_kwargs(op, service_name)

    if is_paginated
      # wrap_paginated defers hooks to actual iteration time (lazy-safe)
      lines << "        wrap_paginated(#{hook_kwargs}) do"
      body_lines = generate_list_method_body(op, path_expr)
      body_lines.each { |l| lines << "  #{l}" }
      lines << '        end'
    else
      lines << "        with_operation(#{hook_kwargs}) do"

      body_lines = if op[:returns_void]
        generate_void_method_body(op, path_expr)
      else
        generate_get_method_body(op, path_expr)
      end

      body_lines.each { |l| lines << "  #{l}" }
      lines << '        end'
    end

    lines << '      end'
    lines
  end

  def build_hook_kwargs(op, service_name)
    kwargs = []
    kwargs << "service: \"#{service_name.downcase}\""
    kwargs << "operation: \"#{op[:method_name]}\""
    kwargs << "is_mutation: #{op[:is_mutation]}"

    resource_param = op[:path_params].last
    kwargs << "resource_id: #{to_snake_case(resource_param[:name])}" if resource_param

    kwargs.join(', ')
  end

  def build_params(op)
    params = []

    # Path parameters as keyword args
    op[:path_params].each do |p|
      params << "#{to_snake_case(p[:name])}:"
    end

    # Binary upload parameters
    if op[:has_binary_body]
      params << 'data:'
      params << 'content_type:'
    elsif op[:has_body]
      # Required body params first (no default), then optional (with nil default)
      required_body_params = op[:body_params].select { |b| b[:required] }
      optional_body_params = op[:body_params].reject { |b| b[:required] }

      required_body_params.each do |b|
        params << "#{to_snake_case(b[:name])}:"
      end

      optional_body_params.each do |b|
        params << "#{to_snake_case(b[:name])}: nil"
      end
    end

    # Query parameters - required first, then optional
    required_query_params = op[:query_params].select { |q| q[:required] }
    optional_query_params = op[:query_params].reject { |q| q[:required] }

    required_query_params.each do |q|
      params << "#{to_snake_case(q[:name])}:"
    end

    optional_query_params.each do |q|
      params << "#{to_snake_case(q[:name])}: nil"
    end

    params.join(', ')
  end

  # Build body hash expression from explicit body params
  def build_body_expression(op)
    return '{}' unless op[:body_params]&.any?

    param_mappings = op[:body_params].map do |b|
      ruby_name = to_snake_case(b[:name])
      "#{b[:name]}: #{ruby_name}"
    end

    "compact_params(#{param_mappings.join(', ')})"
  end

  def build_path_expression(op)
    "\"#{op[:path]}\""
  end

  def generate_void_method_body(op, path_expr)
    lines = []
    http_method = op[:http_method].downcase

    if op[:has_body]
      body_expr = build_body_expression(op)
      lines << "        http_#{http_method}(#{path_expr}, body: #{body_expr})"
    else
      lines << "        http_#{http_method}(#{path_expr})"
    end
    lines << '        nil'
    lines
  end

  def generate_list_method_body(op, path_expr)
    lines = []

    if op[:query_params].any?
      param_names = op[:query_params].map { |q| "#{to_snake_case(q[:name])}: #{to_snake_case(q[:name])}" }
      lines << "        params = compact_params(#{param_names.join(', ')})"
      lines << "        paginate(#{path_expr}, params: params)"
    else
      lines << "        paginate(#{path_expr})"
    end

    lines
  end

  def generate_get_method_body(op, path_expr)
    lines = []
    http_method = op[:http_method].downcase

    if op[:has_binary_body]
      if op[:query_params].any?
        query_parts = op[:query_params].map do |q|
          "#{q[:name]}=\#{URI.encode_www_form_component(#{to_snake_case(q[:name])}.to_s)}"
        end
        query_string = query_parts.join('&')
        path_expr_with_query = path_expr.sub(/"$/, "?#{query_string}\"")
        lines << "        http_#{http_method}_raw(#{path_expr_with_query}, body: data, content_type: content_type).json"
      else
        lines << "        http_#{http_method}_raw(#{path_expr}, body: data, content_type: content_type).json"
      end
    elsif op[:has_body]
      body_expr = build_body_expression(op)
      lines << "        http_#{http_method}(#{path_expr}, body: #{body_expr}).json"
    elsif op[:query_params].any?
      param_names = op[:query_params].map { |q| "#{to_snake_case(q[:name])}: #{to_snake_case(q[:name])}" }
      lines << "        http_#{http_method}(#{path_expr}, params: compact_params(#{param_names.join(', ')})).json"
    else
      lines << "        http_#{http_method}(#{path_expr}).json"
    end

    lines
  end
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  openapi_path = nil
  output_dir = nil

  i = 0
  while i < ARGV.length
    case ARGV[i]
    when '--openapi'
      openapi_path = ARGV[i + 1]
      i += 2
    when '--output'
      output_dir = ARGV[i + 1]
      i += 2
    else
      i += 1
    end
  end

  openapi_path ||= File.expand_path('../../openapi.json', __dir__)
  output_dir ||= File.expand_path('../lib/fizzy/generated/services', __dir__)

  unless File.exist?(openapi_path)
    warn "Error: OpenAPI file not found: #{openapi_path}"
    exit 1
  end

  generator = ServiceGenerator.new(openapi_path)
  generator.generate(output_dir)
end
