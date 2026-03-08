# frozen_string_literal: true

require_relative "test_helper"

class FizzyVersionTest < Minitest::Test
  def test_version_present
    refute_empty Fizzy::VERSION
  end

  def test_api_version_present
    refute_empty Fizzy::API_VERSION
  end
end

class FizzyErrorTest < Minitest::Test
  def test_error_message
    e = Fizzy::Error.new(code: "api_error", message: "boom")
    assert_equal "boom", e.message
    assert_equal "api_error", e.code
  end

  def test_error_hint
    e = Fizzy::Error.new(code: "api_error", message: "boom", hint: "try again")
    assert_equal "try again", e.hint
  end

  def test_error_http_status
    e = Fizzy::Error.new(code: "api_error", message: "boom", http_status: 500)
    assert_equal 500, e.http_status
  end

  def test_error_retryable
    e = Fizzy::Error.new(code: "api_error", message: "boom", retryable: true)
    assert e.retryable?
  end

  def test_error_not_retryable_by_default
    e = Fizzy::Error.new(code: "api_error", message: "boom")
    refute e.retryable?
  end

  def test_error_retry_after
    e = Fizzy::Error.new(code: "rate_limit", message: "slow down", retry_after: 30)
    assert_equal 30, e.retry_after
  end

  def test_error_cause
    cause = RuntimeError.new("root")
    e = Fizzy::Error.new(code: "api_error", message: "wrapped", cause: cause)
    assert_equal cause, e.cause
  end

  def test_error_exit_code
    e = Fizzy::Error.new(code: "not_found", message: "gone")
    assert_equal 2, e.exit_code
  end

  def test_exit_code_for_usage
    assert_equal 1, Fizzy::Error.exit_code_for("usage")
  end

  def test_exit_code_for_not_found
    assert_equal 2, Fizzy::Error.exit_code_for("not_found")
  end

  def test_exit_code_for_auth
    assert_equal 3, Fizzy::Error.exit_code_for("auth_required")
  end

  def test_exit_code_for_forbidden
    assert_equal 4, Fizzy::Error.exit_code_for("forbidden")
  end

  def test_exit_code_for_rate_limit
    assert_equal 5, Fizzy::Error.exit_code_for("rate_limit")
  end

  def test_exit_code_for_network
    assert_equal 6, Fizzy::Error.exit_code_for("network")
  end

  def test_exit_code_for_api_error
    assert_equal 7, Fizzy::Error.exit_code_for("api_error")
  end

  def test_exit_code_for_ambiguous
    assert_equal 8, Fizzy::Error.exit_code_for("ambiguous")
  end

  def test_exit_code_for_validation
    assert_equal 9, Fizzy::Error.exit_code_for("validation")
  end

  def test_exit_code_for_unknown
    assert_equal 7, Fizzy::Error.exit_code_for("unknown")
  end
end

class FizzyErrorSubclassTest < Minitest::Test
  def test_usage_error
    e = Fizzy::UsageError.new("bad input")
    assert_equal "usage", e.code
    assert_equal "bad input", e.message
    assert_equal 1, e.exit_code
  end

  def test_usage_error_with_hint
    e = Fizzy::UsageError.new("bad input", hint: "fix it")
    assert_equal "fix it", e.hint
  end

  def test_not_found_error
    e = Fizzy::NotFoundError.new("Board", "42")
    assert_equal "not_found", e.code
    assert_equal 404, e.http_status
    assert_includes e.message, "Board"
    assert_includes e.message, "42"
    assert_equal 2, e.exit_code
  end

  def test_auth_error
    e = Fizzy::AuthError.new
    assert_equal "auth_required", e.code
    assert_equal 401, e.http_status
    refute_nil e.hint
    assert_equal 3, e.exit_code
  end

  def test_auth_error_custom_message
    e = Fizzy::AuthError.new("token expired")
    assert_equal "token expired", e.message
  end

  def test_forbidden_error
    e = Fizzy::ForbiddenError.new
    assert_equal "forbidden", e.code
    assert_equal 403, e.http_status
    refute_nil e.hint
    assert_equal 4, e.exit_code
  end

  def test_rate_limit_error
    e = Fizzy::RateLimitError.new(retry_after: 30)
    assert_equal "rate_limit", e.code
    assert_equal 429, e.http_status
    assert e.retryable?
    assert_equal 30, e.retry_after
    assert_includes e.hint, "30"
    assert_equal 5, e.exit_code
  end

  def test_rate_limit_error_no_retry_after
    e = Fizzy::RateLimitError.new
    assert_nil e.retry_after
    assert_includes e.hint, "slow down"
  end

  def test_network_error
    cause = RuntimeError.new("timeout")
    e = Fizzy::NetworkError.new("Connection failed", cause: cause)
    assert_equal "network", e.code
    assert e.retryable?
    assert_equal cause, e.cause
    assert_equal 6, e.exit_code
  end

  def test_api_error
    e = Fizzy::APIError.new("Server error", http_status: 500, retryable: true)
    assert_equal "api_error", e.code
    assert_equal 500, e.http_status
    assert e.retryable?
    assert_equal 7, e.exit_code
  end

  def test_api_error_from_status
    e = Fizzy::APIError.from_status(502)
    assert_equal "api_error", e.code
    assert_equal 502, e.http_status
    assert e.retryable?
  end

  def test_api_error_from_status_client_error
    e = Fizzy::APIError.from_status(418, "I'm a teapot")
    assert_equal 418, e.http_status
    refute e.retryable?
  end

  def test_ambiguous_error
    e = Fizzy::AmbiguousError.new("board", matches: [ "a", "b" ])
    assert_equal "ambiguous", e.code
    assert_equal %w[a b], e.matches
    assert_includes e.hint, "a"
    assert_includes e.hint, "b"
    assert_equal 8, e.exit_code
  end

  def test_ambiguous_error_no_matches
    e = Fizzy::AmbiguousError.new("board")
    assert_includes e.hint, "specific"
  end

  def test_validation_error
    e = Fizzy::ValidationError.new("Name can't be blank")
    assert_equal "validation", e.code
    assert_equal 400, e.http_status
    assert_equal 9, e.exit_code
  end

  def test_validation_error_422
    e = Fizzy::ValidationError.new("Invalid", http_status: 422)
    assert_equal 422, e.http_status
  end
end

class FizzyErrorFromResponseTest < Minitest::Test
  def test_400_validation
    e = Fizzy.error_from_response(400, '{"error":"Bad request"}')
    assert_kind_of Fizzy::ValidationError, e
    assert_equal "validation", e.code
  end

  def test_401_auth
    e = Fizzy.error_from_response(401, '{"error":"Unauthorized"}')
    assert_kind_of Fizzy::AuthError, e
    assert_equal "auth_required", e.code
  end

  def test_403_forbidden
    e = Fizzy.error_from_response(403, '{"error":"Forbidden"}')
    assert_kind_of Fizzy::ForbiddenError, e
    assert_equal "forbidden", e.code
  end

  def test_404_not_found
    e = Fizzy.error_from_response(404, '{"error":"Not found"}')
    assert_kind_of Fizzy::NotFoundError, e
    assert_equal "not_found", e.code
  end

  def test_422_validation
    e = Fizzy.error_from_response(422, '{"error":"Name blank"}')
    assert_kind_of Fizzy::ValidationError, e
  end

  def test_429_rate_limit
    e = Fizzy.error_from_response(429, nil, retry_after: 60)
    assert_kind_of Fizzy::RateLimitError, e
    assert_equal 60, e.retry_after
  end

  def test_500_api_error
    e = Fizzy.error_from_response(500, '{"error":"Internal"}')
    assert_kind_of Fizzy::APIError, e
    assert e.retryable?
  end

  def test_502_gateway_error
    e = Fizzy.error_from_response(502, nil)
    assert_kind_of Fizzy::APIError, e
    assert e.retryable?
    assert_equal 502, e.http_status
  end

  def test_503_gateway_error
    e = Fizzy.error_from_response(503, nil)
    assert_kind_of Fizzy::APIError, e
    assert e.retryable?
  end

  def test_504_gateway_error
    e = Fizzy.error_from_response(504, nil)
    assert_kind_of Fizzy::APIError, e
    assert e.retryable?
  end

  def test_unknown_status
    e = Fizzy.error_from_response(418, nil)
    assert_kind_of Fizzy::APIError, e
    refute e.retryable?
  end

  def test_nil_body
    e = Fizzy.error_from_response(500)
    assert_kind_of Fizzy::APIError, e
  end

  def test_empty_body
    e = Fizzy.error_from_response(404, "")
    assert_kind_of Fizzy::NotFoundError, e
  end

  def test_malformed_json_body
    e = Fizzy.error_from_response(404, "not json")
    assert_kind_of Fizzy::NotFoundError, e
  end
end

class FizzyConfigTest < Minitest::Test
  def test_default_config
    config = Fizzy::Config.new
    assert_equal "https://fizzy.do", config.base_url
    assert_equal 30, config.timeout
    assert_equal 3, config.max_retries
  end

  def test_custom_config
    config = Fizzy::Config.new(
      base_url: "https://custom.example.com",
      timeout: 60,
      max_retries: 5
    )
    assert_equal "https://custom.example.com", config.base_url
    assert_equal 60, config.timeout
    assert_equal 5, config.max_retries
  end

  def test_base_url_trailing_slash_stripped
    config = Fizzy::Config.new(base_url: "https://fizzy.do/")
    assert_equal "https://fizzy.do", config.base_url
  end

  def test_localhost_allows_http
    config = Fizzy::Config.new(base_url: "http://localhost:3000")
    assert_equal "http://localhost:3000", config.base_url
  end

  def test_127_0_0_1_allows_http
    config = Fizzy::Config.new(base_url: "http://127.0.0.1:3000")
    assert_equal "http://127.0.0.1:3000", config.base_url
  end

  def test_non_localhost_requires_https
    assert_raises(Fizzy::UsageError) do
      Fizzy::Config.new(base_url: "http://evil.example.com")
    end
  end

  def test_invalid_timeout
    assert_raises(ArgumentError) do
      Fizzy::Config.new(timeout: 0)
    end
  end

  def test_negative_max_retries
    assert_raises(ArgumentError) do
      Fizzy::Config.new(max_retries: -1)
    end
  end

  def test_zero_max_pages
    assert_raises(ArgumentError) do
      Fizzy::Config.new(max_pages: 0)
    end
  end

  def test_base_delay_default
    config = Fizzy::Config.new
    assert_equal 1.0, config.base_delay
  end

  def test_max_jitter_default
    config = Fizzy::Config.new
    assert_equal 0.1, config.max_jitter
  end

  def test_max_pages_default
    config = Fizzy::Config.new
    assert_equal 10_000, config.max_pages
  end
end

class FizzySecurityTest < Minitest::Test
  def test_truncate_short_string
    assert_equal "short", Fizzy::Security.truncate("short", 100)
  end

  def test_truncate_long_string
    result = Fizzy::Security.truncate("this is a long string", 10)
    assert_equal 10, result.bytesize
    assert result.end_with?("...")
  end

  def test_truncate_nil
    assert_nil Fizzy::Security.truncate(nil)
  end

  def test_truncate_exact_length
    assert_equal "exact", Fizzy::Security.truncate("exact", 5)
  end

  def test_require_https_valid
    Fizzy::Security.require_https!("https://fizzy.do")
  end

  def test_require_https_rejects_http
    assert_raises(Fizzy::UsageError) do
      Fizzy::Security.require_https!("http://fizzy.do")
    end
  end

  def test_same_origin_same_host
    assert Fizzy::Security.same_origin?("https://fizzy.do/a", "https://fizzy.do/b")
  end

  def test_same_origin_different_host
    refute Fizzy::Security.same_origin?("https://fizzy.do/a", "https://evil.com/b")
  end

  def test_same_origin_different_scheme
    refute Fizzy::Security.same_origin?("https://fizzy.do/a", "http://fizzy.do/a")
  end

  def test_same_origin_default_port
    assert Fizzy::Security.same_origin?("https://fizzy.do:443/a", "https://fizzy.do/b")
  end

  def test_resolve_url_relative
    assert_equal "https://fizzy.do/page2", Fizzy::Security.resolve_url("https://fizzy.do/page1", "/page2")
  end

  def test_localhost_detection
    assert Fizzy::Security.localhost?("http://localhost")
    assert Fizzy::Security.localhost?("http://localhost:3000")
    assert Fizzy::Security.localhost?("http://127.0.0.1")
    assert Fizzy::Security.localhost?("http://127.0.0.1:8080")
    refute Fizzy::Security.localhost?("https://fizzy.do")
    refute Fizzy::Security.localhost?("https://example.com")
  end

  def test_localhost_subdomain
    assert Fizzy::Security.localhost?("http://sub.localhost")
  end

  def test_check_body_size_ok
    Fizzy::Security.check_body_size!("small body", 1_000_000)
  end

  def test_check_body_size_too_large
    assert_raises(Fizzy::APIError) do
      Fizzy::Security.check_body_size!("x" * 100, 50)
    end
  end

  def test_check_body_size_nil
    Fizzy::Security.check_body_size!(nil, 100)
  end

  def test_redact_headers
    headers = {
      "Authorization" => "Bearer secret",
      "Cookie" => "session=abc",
      "Content-Type" => "application/json",
      "X-Csrf-Token" => "token123"
    }
    redacted = Fizzy::Security.redact_headers(headers)
    assert_equal "[REDACTED]", redacted["Authorization"]
    assert_equal "[REDACTED]", redacted["Cookie"]
    assert_equal "application/json", redacted["Content-Type"]
    assert_equal "[REDACTED]", redacted["X-Csrf-Token"]

    # Original should be untouched
    assert_equal "Bearer secret", headers["Authorization"]
  end
end

class FizzyPaginationSecurityTest < Minitest::Test
  def test_cross_origin_pagination_raises
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get("/boards.json") do
      [
        200,
        { "Content-Type" => "application/json", "Link" => '<https://evil.com/boards?page=2>; rel="next"' },
        '[{"id": 1}]'
      ]
    end

    config = Fizzy::Config.new(base_url: "https://fizzy.do")
    tp = Fizzy::StaticTokenProvider.new("token")
    http = Fizzy::Http.new(config: config, token_provider: tp)

    # Replace the Faraday client with our stubs
    http.instance_variable_set(:@faraday, Faraday.new(url: "https://fizzy.do") { |f|
      f.request :json
      f.adapter :test, stubs
    })

    assert_raises(Fizzy::APIError) do
      http.paginate("/boards.json") { |_item| }
    end
  end
end

class FizzyStaticTokenProviderTest < Minitest::Test
  def test_access_token
    tp = Fizzy::StaticTokenProvider.new("my-token")
    assert_equal "my-token", tp.access_token
  end

  def test_nil_token_raises
    assert_raises(ArgumentError) do
      Fizzy::StaticTokenProvider.new(nil)
    end
  end

  def test_empty_token_raises
    assert_raises(ArgumentError) do
      Fizzy::StaticTokenProvider.new("")
    end
  end

  def test_not_refreshable
    tp = Fizzy::StaticTokenProvider.new("my-token")
    refute tp.refreshable?
    refute tp.refresh
  end
end

class FizzyClientTest < Minitest::Test
  def test_requires_auth
    config = Fizzy::Config.new
    assert_raises(ArgumentError) do
      Fizzy::Client.new(config: config)
    end
  end

  def test_rejects_both_auth_options
    config = Fizzy::Config.new
    tp = Fizzy::StaticTokenProvider.new("token")
    auth = Fizzy::BearerAuth.new(tp)
    assert_raises(ArgumentError) do
      Fizzy::Client.new(config: config, token_provider: tp, auth_strategy: auth)
    end
  end

  def test_creates_with_token_provider
    config = Fizzy::Config.new
    tp = Fizzy::StaticTokenProvider.new("token")
    client = Fizzy::Client.new(config: config, token_provider: tp)
    assert_equal config, client.config
  end

  def test_creates_with_auth_strategy
    config = Fizzy::Config.new
    tp = Fizzy::StaticTokenProvider.new("token")
    auth = Fizzy::BearerAuth.new(tp)
    client = Fizzy::Client.new(config: config, auth_strategy: auth)
    assert_equal config, client.config
  end

  def test_service_accessors
    config = Fizzy::Config.new
    tp = Fizzy::StaticTokenProvider.new("token")
    client = Fizzy::Client.new(config: config, token_provider: tp)

    assert_kind_of Fizzy::Services::BoardsService, client.boards
    assert_kind_of Fizzy::Services::CardsService, client.cards
    assert_kind_of Fizzy::Services::ColumnsService, client.columns
    assert_kind_of Fizzy::Services::CommentsService, client.comments
    assert_kind_of Fizzy::Services::StepsService, client.steps
    assert_kind_of Fizzy::Services::ReactionsService, client.reactions
    assert_kind_of Fizzy::Services::NotificationsService, client.notifications
    assert_kind_of Fizzy::Services::TagsService, client.tags
    assert_kind_of Fizzy::Services::UsersService, client.users
    assert_kind_of Fizzy::Services::PinsService, client.pins
    assert_kind_of Fizzy::Services::UploadsService, client.uploads
    assert_kind_of Fizzy::Services::WebhooksService, client.webhooks
    assert_kind_of Fizzy::Services::SessionsService, client.sessions
    assert_kind_of Fizzy::Services::DevicesService, client.devices
    assert_kind_of Fizzy::Services::IdentityService, client.identity
  end

  def test_services_are_memoized
    config = Fizzy::Config.new
    tp = Fizzy::StaticTokenProvider.new("token")
    client = Fizzy::Client.new(config: config, token_provider: tp)

    assert_same client.boards, client.boards
    assert_same client.cards, client.cards
  end
end

class FizzyConvenienceClientTest < Minitest::Test
  def test_client_with_access_token
    client = Fizzy.client(access_token: "test-token")
    assert_kind_of Fizzy::Client, client
  end

  def test_client_with_auth_strategy
    tp = Fizzy::StaticTokenProvider.new("token")
    auth = Fizzy::BearerAuth.new(tp)
    client = Fizzy.client(auth: auth)
    assert_kind_of Fizzy::Client, client
  end

  def test_client_rejects_both
    tp = Fizzy::StaticTokenProvider.new("token")
    auth = Fizzy::BearerAuth.new(tp)
    assert_raises(ArgumentError) do
      Fizzy.client(access_token: "token", auth: auth)
    end
  end

  def test_client_rejects_neither
    assert_raises(ArgumentError) do
      Fizzy.client
    end
  end
end

class FizzyBearerAuthTest < Minitest::Test
  def test_authenticate_sets_authorization_header
    tp = Fizzy::StaticTokenProvider.new("my-secret-token")
    auth = Fizzy::BearerAuth.new(tp)
    headers = {}
    auth.authenticate(headers)
    assert_equal "Bearer my-secret-token", headers["Authorization"]
  end

  def test_token_provider_accessor
    tp = Fizzy::StaticTokenProvider.new("token")
    auth = Fizzy::BearerAuth.new(tp)
    assert_same tp, auth.token_provider
  end
end

class FizzyErrorCodeConstantsTest < Minitest::Test
  def test_error_code_constants
    assert_equal "usage", Fizzy::ErrorCode::USAGE
    assert_equal "not_found", Fizzy::ErrorCode::NOT_FOUND
    assert_equal "auth_required", Fizzy::ErrorCode::AUTH
    assert_equal "forbidden", Fizzy::ErrorCode::FORBIDDEN
    assert_equal "rate_limit", Fizzy::ErrorCode::RATE_LIMIT
    assert_equal "network", Fizzy::ErrorCode::NETWORK
    assert_equal "api_error", Fizzy::ErrorCode::API
    assert_equal "ambiguous", Fizzy::ErrorCode::AMBIGUOUS
    assert_equal "validation", Fizzy::ErrorCode::VALIDATION
  end

  def test_exit_code_constants
    assert_equal 0, Fizzy::ExitCode::OK
    assert_equal 1, Fizzy::ExitCode::USAGE
    assert_equal 2, Fizzy::ExitCode::NOT_FOUND
    assert_equal 3, Fizzy::ExitCode::AUTH
    assert_equal 4, Fizzy::ExitCode::FORBIDDEN
    assert_equal 5, Fizzy::ExitCode::RATE_LIMIT
    assert_equal 6, Fizzy::ExitCode::NETWORK
    assert_equal 7, Fizzy::ExitCode::API
    assert_equal 8, Fizzy::ExitCode::AMBIGUOUS
    assert_equal 9, Fizzy::ExitCode::VALIDATION
  end
end
