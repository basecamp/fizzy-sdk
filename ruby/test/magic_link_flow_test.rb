# frozen_string_literal: true

require_relative "test_helper"

# Fizzy's magic-link sign-in: POST /session.json with the address answers 201 and the pending
# token, and POST /session/magic_link.json redeems the code only with that token sent back as
# the pending_authentication_token cookie.
class FizzyMagicLinkFlowTest < Minitest::Test
  def setup
    @requests = []
  end

  def test_create_session_posts_the_address_and_keeps_the_pending_token
    flow = flow_with do |stubs|
      stubs.post("/session.json") { |env| record(env, 201, { pending_authentication_token: "pend-1" }) }
    end

    assert_equal "pend-1", flow.create_session(email_address: "jane@example.com")
    assert_equal "pend-1", flow.pending_token
    assert_equal 1, @requests.size
    request = @requests.first
    assert_equal "/session.json", request[:path]
    assert_equal({ "email_address" => "jane@example.com" }, request[:body])
    assert_nil request[:headers]["Cookie"], "no pending token yet, so no cookie"
    assert_nil request[:headers]["Authorization"], "a sign-in has no credentials to send"
  end

  def test_redeem_sends_the_code_with_the_pending_token_as_a_cookie
    flow = flow_with do |stubs|
      stubs.post("/session.json") { |env| record(env, 201, { pending_authentication_token: "pend/1+=" }) }
      stubs.post("/session/magic_link.json") do |env|
        record(env, 200, { session_token: "sess-1", requires_signup_completion: false })
      end
    end

    flow.create_session(email_address: "jane@example.com")
    session = flow.redeem(code: "ABC123")

    assert_equal({ "session_token" => "sess-1", "requires_signup_completion" => false }, session)
    redeem = @requests.last
    assert_equal "/session/magic_link.json", redeem[:path]
    assert_equal({ "code" => "ABC123" }, redeem[:body])
    assert_equal "pending_authentication_token=pend%2F1%2B%3D", redeem[:headers]["Cookie"]
  end

  def test_redeem_resumes_a_sign_in_another_flow_started
    flow = flow_with(pending_token: "pend-2") do |stubs|
      stubs.post("/session/magic_link.json") do |env|
        record(env, 200, { session_token: "sess-2", requires_signup_completion: true })
      end
    end

    assert_equal true, flow.redeem(code: "XYZ789")["requires_signup_completion"]
    assert_equal 1, @requests.size
    assert_equal "pending_authentication_token=pend-2", @requests.first[:headers]["Cookie"]
  end

  def test_redeem_without_a_pending_sign_in_is_a_usage_error
    flow = flow_with { |_stubs| }

    assert_raises(Fizzy::UsageError) { flow.redeem(code: "ABC123") }
    assert_empty @requests
  end

  def test_a_refused_code_is_an_auth_error_and_is_not_resent
    flow = flow_with(pending_token: "pend-3") do |stubs|
      stubs.post("/session/magic_link.json") { |env| record(env, 401, { message: "Try another code." }) }
    end

    assert_raises(Fizzy::AuthError) { flow.redeem(code: "WRONG1") }
    assert_equal 1, @requests.size
  end

  def test_an_answer_without_a_pending_token_is_an_api_error
    flow = flow_with do |stubs|
      stubs.post("/session.json") { |env| record(env, 201, {}) }
    end

    assert_raises(Fizzy::APIError) { flow.create_session(email_address: "jane@example.com") }
    assert_nil flow.pending_token
  end

  def test_the_flow_refuses_a_plain_http_origin
    assert_raises(Fizzy::UsageError, ArgumentError) { Fizzy::MagicLinkFlow.new(base_url: "http://fizzy.example.com") }
  end

  private

  def record(env, status, body)
    @requests << {
      path: env.url.path,
      body: env.body.nil? || env.body.empty? ? nil : JSON.parse(env.body),
      headers: env.request_headers.to_h
    }
    [ status, { "Content-Type" => "application/json" }, JSON.generate(body) ]
  end

  def flow_with(pending_token: nil)
    stubs = Faraday::Adapter::Test::Stubs.new
    yield stubs
    flow = Fizzy::MagicLinkFlow.new(base_url: "https://fizzy.do", pending_token: pending_token)
    http = flow.instance_variable_get(:@client).http
    http.instance_variable_set(:@faraday, Faraday.new(url: "https://fizzy.do") { |f|
      f.request :json
      f.response :raise_error
      f.adapter :test, stubs
    })
    flow
  end
end
