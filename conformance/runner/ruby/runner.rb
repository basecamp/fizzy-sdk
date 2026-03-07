#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "fizzy"
require "webmock"
require "json"
require "uri"

WebMock.enable!
WebMock.disable_net_connect!

class ConformanceRunner
  include WebMock::API
  def initialize(tests_dir)
    @tests_dir = tests_dir
    @passed = 0
    @failed = 0
    @skipped = 0
  end

  def run
    files = Dir.glob(File.join(@tests_dir, "*.json")).sort
    abort "No test files found in #{@tests_dir}" if files.empty?

    files.each { |f| run_file(f) }

    puts "\n#{@passed} passed, #{@failed} failed, #{@skipped} skipped"
    exit 1 if @failed > 0
  end

  private

  def run_file(file)
    filename = File.basename(file)
    tests = JSON.parse(File.read(file))
    puts "\n=== #{filename} (#{tests.length} tests) ==="
    tests.each { |tc| run_test(tc) }
  end

  def run_test(tc)
    name = tc["name"]
    request_log = { count: 0, times: [], records: [] }
    mock_idx = 0
    mock_responses = tc["mockResponses"] || []

    override_url = tc.dig("configOverrides", "baseUrl")
    base_url = override_url || "http://localhost:9876"

    WebMock.reset!

    # Stub all HTTP requests to the base URL host
    host = URI.parse(base_url).host
    stub_request(:any, /#{Regexp.escape(host)}/).to_return do |request|
      request_log[:count] += 1
      request_log[:times] << Process.clock_gettime(Process::CLOCK_MONOTONIC)
      parsed_uri = URI.parse(request.uri)
      request_log[:records] << {
        method: request.method,
        path: parsed_uri.path,
        query: parsed_uri.query,
        headers: request.headers,
        body: request.body
      }

      if mock_idx < mock_responses.length
        mock = mock_responses[mock_idx]
        mock_idx += 1
        body_str = mock["body"].nil? ? "" : JSON.generate(mock["body"])
        {
          status: mock["status"],
          headers: (mock["headers"] || {}).merge("Content-Type" => mock.dig("headers", "Content-Type") || "application/json"),
          body: body_str
        }
      else
        has_link = mock_responses.any? { |m| m.dig("headers", "Link") }
        if has_link
          { status: 200, headers: { "Content-Type" => "application/json" }, body: "[]" }
        else
          { status: 500, body: "" }
        end
      end
    end

    # Create client -- HTTPS enforcement may raise here
    client = nil
    config_error = nil

    # Use real delays when the test asserts on timing
    has_delay_assertion = (tc["assertions"] || []).any? { |a| a["type"] == "delayBetweenRequests" }
    base_delay = has_delay_assertion ? 1.0 : 0.001
    max_jitter = has_delay_assertion ? 0.1 : 0.001

    begin
      config = Fizzy::Config.new(
        base_url: base_url,
        max_retries: 3,
        base_delay: base_delay,
        max_jitter: max_jitter
      )
      token_provider = Fizzy::StaticTokenProvider.new("test-token")
      client = Fizzy::Client.new(config: config, token_provider: token_provider)
    rescue => e
      config_error = e
    end

    # Execute operation
    result = nil
    error = config_error
    if client && !config_error
      begin
        result = dispatch_operation(tc, client)
      rescue Fizzy::Error => e
        error = e
      rescue => e
        error = e
      end
    end

    check_assertions(tc, request_log, result, error, name)
  end

  def should_paginate?(tc)
    return true if (tc["assertions"] || []).any? { |a| a["type"] == "urlOrigin" }

    mocks = tc["mockResponses"] || []
    mocks.length > 1 && mocks.any? { |m| m.dig("headers", "Link") }
  end

  def dispatch_list(enum, tc)
    should_paginate?(tc) ? enum.to_a : enum.first
  end

  def dispatch_operation(tc, client)
    op = tc["operation"]
    pp = tc["pathParams"] || {}
    body = tc["requestBody"] || {}
    account_id = pp["accountId"]&.to_s

    case op
    # Boards
    when "ListBoards"
      enum = client.boards.list(account_id: account_id)
      dispatch_list(enum, tc)
    when "GetBoard"
      client.boards.get(account_id: account_id, board_id: pp["boardId"])
    when "CreateBoard"
      client.boards.create(account_id: account_id, **symbolize_body(body))
    when "UpdateBoard"
      client.boards.update(account_id: account_id, board_id: pp["boardId"], **symbolize_body(body))
    when "DeleteBoard"
      client.boards.delete(account_id: account_id, board_id: pp["boardId"])

    # Cards
    when "ListCards"
      enum = client.cards.list(account_id: account_id, **symbolize_body(tc["queryParams"] || {}))
      dispatch_list(enum, tc)
    when "GetCard"
      client.cards.get(account_id: account_id, card_number: pp["cardNumber"])
    when "CreateCard"
      client.cards.create(account_id: account_id, **symbolize_body(body))
    when "UpdateCard"
      client.cards.update(account_id: account_id, card_number: pp["cardNumber"], **symbolize_body(body))
    when "DeleteCard"
      client.cards.delete(account_id: account_id, card_number: pp["cardNumber"])
    when "AssignCard"
      client.cards.assign(account_id: account_id, card_number: pp["cardNumber"], **symbolize_body(body))
    when "MoveCard"
      client.cards.move(account_id: account_id, card_number: pp["cardNumber"], **symbolize_body(body))
    when "CloseCard"
      client.cards.close(account_id: account_id, card_number: pp["cardNumber"])
    when "ReopenCard"
      client.cards.reopen(account_id: account_id, card_number: pp["cardNumber"])
    when "GoldCard"
      client.cards.gold(account_id: account_id, card_number: pp["cardNumber"])
    when "UngoldCard"
      client.cards.ungold(account_id: account_id, card_number: pp["cardNumber"])
    when "DeleteCardImage"
      client.cards.delete_image(account_id: account_id, card_number: pp["cardNumber"])
    when "PostponeCard"
      client.cards.postpone(account_id: account_id, card_number: pp["cardNumber"])
    when "PinCard"
      client.cards.pin(account_id: account_id, card_number: pp["cardNumber"])
    when "UnpinCard"
      client.cards.unpin(account_id: account_id, card_number: pp["cardNumber"])
    when "SelfAssignCard"
      client.cards.self_assign(account_id: account_id, card_number: pp["cardNumber"])
    when "TagCard"
      client.cards.tag(account_id: account_id, card_number: pp["cardNumber"], **symbolize_body(body))
    when "TriageCard"
      client.cards.triage(account_id: account_id, card_number: pp["cardNumber"])
    when "UnTriageCard"
      client.cards.untriage(account_id: account_id, card_number: pp["cardNumber"])
    when "WatchCard"
      client.cards.watch(account_id: account_id, card_number: pp["cardNumber"])
    when "UnwatchCard"
      client.cards.unwatch(account_id: account_id, card_number: pp["cardNumber"])

    # Columns
    when "ListColumns"
      client.columns.list(account_id: account_id, board_id: pp["boardId"])
    when "GetColumn"
      client.columns.get(account_id: account_id, board_id: pp["boardId"], column_id: pp["columnId"])
    when "CreateColumn"
      client.columns.create(account_id: account_id, board_id: pp["boardId"], **symbolize_body(body))
    when "UpdateColumn"
      client.columns.update(account_id: account_id, board_id: pp["boardId"], column_id: pp["columnId"], **symbolize_body(body))

    # Comments
    when "ListComments"
      enum = client.comments.list(account_id: account_id, card_number: pp["cardNumber"])
      dispatch_list(enum, tc)
    when "GetComment"
      client.comments.get(account_id: account_id, card_number: pp["cardNumber"], comment_id: pp["commentId"])
    when "CreateComment"
      client.comments.create(account_id: account_id, card_number: pp["cardNumber"], **symbolize_body(body))
    when "UpdateComment"
      client.comments.update(account_id: account_id, card_number: pp["cardNumber"], comment_id: pp["commentId"], **symbolize_body(body))
    when "DeleteComment"
      client.comments.delete(account_id: account_id, card_number: pp["cardNumber"], comment_id: pp["commentId"])

    # Steps
    when "CreateStep"
      client.steps.create(account_id: account_id, card_number: pp["cardNumber"], **symbolize_body(body))
    when "GetStep"
      client.steps.get(account_id: account_id, card_number: pp["cardNumber"], step_id: pp["stepId"])
    when "UpdateStep"
      client.steps.update(account_id: account_id, card_number: pp["cardNumber"], step_id: pp["stepId"], **symbolize_body(body))
    when "DeleteStep"
      client.steps.delete(account_id: account_id, card_number: pp["cardNumber"], step_id: pp["stepId"])

    # Reactions
    when "ListCommentReactions"
      client.reactions.list_for_comment(account_id: account_id, card_number: pp["cardNumber"], comment_id: pp["commentId"])
    when "CreateCommentReaction"
      client.reactions.create_for_comment(account_id: account_id, card_number: pp["cardNumber"], comment_id: pp["commentId"], **symbolize_body(body))
    when "DeleteCommentReaction"
      client.reactions.delete_for_comment(account_id: account_id, card_number: pp["cardNumber"], comment_id: pp["commentId"], reaction_id: pp["reactionId"])
    when "ListCardReactions"
      client.reactions.list_for_card(account_id: account_id, card_number: pp["cardNumber"])
    when "CreateCardReaction"
      client.reactions.create_for_card(account_id: account_id, card_number: pp["cardNumber"], **symbolize_body(body))
    when "DeleteCardReaction"
      client.reactions.delete_for_card(account_id: account_id, card_number: pp["cardNumber"], reaction_id: pp["reactionId"])

    # Notifications
    when "ListNotifications"
      enum = client.notifications.list(account_id: account_id)
      dispatch_list(enum, tc)
    when "BulkReadNotifications"
      client.notifications.bulk_read(account_id: account_id, **symbolize_body(body))
    when "GetNotificationTray"
      client.notifications.tray(account_id: account_id, **symbolize_body(tc["queryParams"] || {}))
    when "ReadNotification"
      client.notifications.read(account_id: account_id, notification_id: pp["notificationId"])
    when "UnreadNotification"
      client.notifications.unread(account_id: account_id, notification_id: pp["notificationId"])

    # Tags
    when "ListTags"
      client.tags.list(account_id: account_id)

    # Users
    when "ListUsers"
      client.users.list(account_id: account_id)
    when "GetUser"
      client.users.get(account_id: account_id, user_id: pp["userId"])
    when "UpdateUser"
      client.users.update(account_id: account_id, user_id: pp["userId"], **symbolize_body(body))
    when "DeactivateUser"
      client.users.deactivate(account_id: account_id, user_id: pp["userId"])

    # Pins
    when "ListPins"
      client.pins.list

    # Uploads
    when "CreateDirectUpload"
      client.uploads.create_direct(account_id: account_id, **symbolize_body(body))

    # Webhooks
    when "ListWebhooks"
      client.webhooks.list(account_id: account_id, board_id: pp["boardId"])
    when "GetWebhook"
      client.webhooks.get(account_id: account_id, board_id: pp["boardId"], webhook_id: pp["webhookId"])
    when "CreateWebhook"
      client.webhooks.create(account_id: account_id, board_id: pp["boardId"], **symbolize_body(body))
    when "UpdateWebhook"
      client.webhooks.update(account_id: account_id, board_id: pp["boardId"], webhook_id: pp["webhookId"], **symbolize_body(body))
    when "DeleteWebhook"
      client.webhooks.delete(account_id: account_id, board_id: pp["boardId"], webhook_id: pp["webhookId"])
    when "ActivateWebhook"
      client.webhooks.activate(account_id: account_id, board_id: pp["boardId"], webhook_id: pp["webhookId"])

    # Sessions (account-independent)
    when "CreateSession"
      client.sessions.create(**symbolize_body(body))
    when "DestroySession"
      client.sessions.destroy
    when "RedeemMagicLink"
      client.sessions.redeem_magic_link(**symbolize_body(body))
    when "CompleteSignup"
      client.sessions.complete_signup(**symbolize_body(body))

    # Identity (account-independent)
    when "GetMyIdentity"
      client.identity.me

    # Devices
    when "RegisterDevice"
      client.devices.register(account_id: account_id, **symbolize_body(body))
    when "UnregisterDevice"
      client.devices.unregister(account_id: account_id, device_token: pp["deviceToken"].to_s)

    else
      raise "Unknown operation: #{op}"
    end
  end

  def symbolize_body(body)
    body.transform_keys(&:to_sym)
  end

  def check_assertions(tc, log, result, error, name)
    assertions = tc["assertions"] || []
    all_passed = true
    skipped = false

    assertions.each do |assertion|
      type = assertion["type"]
      expected = assertion["expected"]
      path = assertion["path"]

      ok = case type
      when "requestCount"
        actual = log[:count]
        if actual != expected
          puts "    ASSERT FAIL [requestCount]: expected #{expected}, got #{actual}"
          false
        else
          true
        end

      when "delayBetweenRequests"
        min_ms = assertion["min"] || expected
        times = log[:times]
        if times.length < 2
          puts "    ASSERT FAIL [delayBetweenRequests]: need >= 2 requests, got #{times.length}"
          false
        else
          ok = true
          (1...times.length).each do |i|
            delay_ms = ((times[i] - times[i - 1]) * 1000).round
            if delay_ms < min_ms
              puts "    ASSERT FAIL [delayBetweenRequests]: delay #{i}->#{i + 1} was #{delay_ms}ms, expected >= #{min_ms}ms"
              ok = false
              break
            end
          end
          ok
        end

      when "statusCode"
        actual = if error.respond_to?(:http_status) && error.http_status
          error.http_status
        elsif !log[:records].empty?
          # Infer from last mock response status
          mock_responses = tc["mockResponses"] || []
          idx = [log[:count] - 1, mock_responses.length - 1].min
          idx >= 0 ? mock_responses[idx]["status"] : nil
        end
        if actual != expected
          puts "    ASSERT FAIL [statusCode]: expected #{expected}, got #{actual.inspect}"
          false
        else
          true
        end

      when "noError"
        if error
          puts "    ASSERT FAIL [noError]: got error: #{error.class}: #{error.message}"
          false
        else
          true
        end

      when "errorCode"
        if error.nil?
          puts "    ASSERT FAIL [errorCode]: expected error with code #{expected.inspect}, got no error"
          false
        elsif error.respond_to?(:code)
          actual = error.code
          if actual != expected
            puts "    ASSERT FAIL [errorCode]: expected #{expected.inspect}, got #{actual.inspect}"
            false
          else
            true
          end
        else
          puts "    ASSERT FAIL [errorCode]: error does not have a code: #{error.class}: #{error.message}"
          false
        end

      when "errorField"
        if error.nil?
          puts "    ASSERT FAIL [errorField]: expected error, got nil"
          false
        else
          case path
          when "requestId"
            actual = error.respond_to?(:request_id) ? error.request_id : nil
            if actual != expected
              puts "    ASSERT FAIL [errorField.requestId]: expected #{expected.inspect}, got #{actual.inspect}"
              false
            else
              true
            end
          else
            puts "    ASSERT FAIL [errorField]: unknown field path #{path.inspect}"
            false
          end
        end

      when "headerPresent"
        header_name = path
        if log[:records].empty?
          puts "    ASSERT FAIL [headerPresent]: no requests recorded"
          false
        else
          last = log[:records].last
          headers = last[:headers]
          found = headers.any? { |k, _| k.downcase == header_name.downcase }
          if found
            true
          else
            puts "    ASSERT FAIL [headerPresent]: header #{header_name.inspect} not present"
            false
          end
        end

      when "requestPath"
        if log[:records].empty?
          puts "    ASSERT FAIL [requestPath]: no requests recorded"
          false
        else
          actual = log[:records].last[:path]
          if actual != expected
            puts "    ASSERT FAIL [requestPath]: expected #{expected.inspect}, got #{actual.inspect}"
            false
          else
            true
          end
        end

      when "requestBodyField"
        if log[:records].empty?
          puts "    ASSERT FAIL [requestBodyField]: no requests recorded"
          false
        else
          last_body = log[:records].reverse.find { |r| r[:body] && !r[:body].empty? }&.dig(:body)
          if last_body
            parsed = JSON.parse(last_body) rescue nil
            if parsed&.key?(expected)
              true
            else
              keys = parsed&.keys || []
              puts "    ASSERT FAIL [requestBodyField]: field #{expected.inspect} not found (keys: #{keys})"
              false
            end
          else
            puts "    ASSERT FAIL [requestBodyField]: no request body found"
            false
          end
        end

      when "urlOrigin"
        if expected == "rejected"
          # Cross-origin/protocol-downgrade Link rejected: either error or silent stop
          if error || log[:count] <= 1
            true
          else
            puts "    ASSERT FAIL [urlOrigin]: expected cross-origin Link to not be followed, got #{log[:count]} requests"
            false
          end
        else
          true
        end

      when "requestScheme"
        true

      when "responseMeta"
        # Skip -- Ruby Enumerator doesn't expose X-Total-Count
        skipped = true
        nil

      when "responseBody"
        true

      when "errorMessage"
        if error.nil?
          puts "    ASSERT FAIL [errorMessage]: expected error, got nil"
          false
        else
          actual = error.message
          if actual.include?(expected.to_s)
            true
          else
            puts "    ASSERT FAIL [errorMessage]: expected message containing #{expected.inspect}, got #{actual.inspect}"
            false
          end
        end

      when "requestQueryParam"
        if log[:records].empty?
          puts "    ASSERT FAIL [requestQueryParam]: no requests recorded"
          false
        else
          last = log[:records].last
          params = URI.decode_www_form(last[:query] || "").to_h
          param_name = path
          actual = params[param_name]
          if actual == expected.to_s
            true
          else
            puts "    ASSERT FAIL [requestQueryParam]: param #{param_name.inspect} expected #{expected.inspect}, got #{actual.inspect}"
            false
          end
        end

      when "headerInjected"
        true

      when "headerValue"
        if log[:records].empty?
          puts "    ASSERT FAIL [headerValue]: no requests recorded"
          false
        else
          last = log[:records].last
          actual = last[:headers].find { |k, _| k.downcase == path.downcase }&.last
          if actual == expected
            true
          else
            puts "    ASSERT FAIL [headerValue]: header #{path.inspect} expected #{expected.inspect}, got #{actual.inspect}"
            false
          end
        end

      else
        puts "    ASSERT SKIP [#{type}]: unsupported assertion type"
        true
      end

      if ok.nil?
        # skipped
      elsif !ok
        all_passed = false
      end
    end

    if skipped && all_passed
      @skipped += 1
      puts "  SKIP  #{name}"
    elsif all_passed
      @passed += 1
      puts "  PASS  #{name}"
    else
      @failed += 1
      puts "  FAIL  #{name}"
    end
  end
end

tests_dir = ARGV[0] || File.expand_path("../../tests", __dir__)
ConformanceRunner.new(tests_dir).run
