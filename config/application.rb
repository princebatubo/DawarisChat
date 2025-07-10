# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)

Dotenv::Rails.load

require 'ddtrace' if ENV.fetch('DD_TRACE_AGENT_URL', false).present?
require 'elastic-apm' if ENV.fetch('ELASTIC_APM_SECRET_TOKEN', false).present?
require 'scout_apm' if ENV.fetch('SCOUT_KEY', false).present?

if ENV.fetch('NEW_RELIC_LICENSE_KEY', false).present?
  require 'newrelic-sidekiq-metrics'
  require 'newrelic_rpm'
end

if ENV.fetch('SENTRY_DSN', false).present?
  require 'sentry-ruby'
  require 'sentry-rails'
  require 'sentry-sidekiq'
end

if ENV.fetch('JUDOSCALE_URL', false).present?
  require 'judoscale-rails'
  require 'judoscale-sidekiq'
end

module DawarisChat
  class Application < Rails::Application
    config.load_defaults 7.0

    config.eager_load_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('enterprise/lib')
    config.eager_load_paths << Rails.root.join('enterprise/listeners')
    config.eager_load_paths += Dir["#{Rails.root}/enterprise/app/**"]
    config.paths['app/views'].unshift('enterprise/app/views')

    config.generators.javascripts = false
    config.generators.stylesheets = false

    config.x = config_for(:app).with_indifferent_access

    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess]
  end

  def self.config
    @config ||= Rails.configuration.x
  end

  def self.redis_ssl_verify_mode
    ENV['REDIS_OPENSSL_VERIFY_MODE'] == 'none' ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
  end
end
