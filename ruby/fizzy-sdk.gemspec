# frozen_string_literal: true

require_relative 'lib/fizzy/version'

Gem::Specification.new do |spec|
  spec.name = 'fizzy-sdk'
  spec.version = Fizzy::VERSION
  spec.authors = [ 'Basecamp' ]
  spec.email = [ 'support@basecamp.com' ]

  spec.summary = 'Official Ruby SDK for the Fizzy API'
  spec.description = 'A Ruby SDK for the Fizzy API with automatic retry, ' \
                     'exponential backoff, Link header pagination, and observability hooks.'
  spec.homepage = 'https://github.com/basecamp/fizzy-sdk'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/releases"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.require_paths = [ 'lib' ]

  # Runtime dependencies
  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'zeitwerk', '~> 2.6'

  # Development dependencies
  spec.add_development_dependency 'minitest', '~> 6.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop-37signals'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'webmock', '~> 3.24'
  spec.add_development_dependency 'irb', '~> 1.15'
  spec.add_development_dependency 'rdoc', '~> 7.1'
  spec.add_development_dependency 'webrick', '~> 1.9'
  spec.add_development_dependency 'yard', '~> 0.9'
end
