ruby
# frozen_string_literal: true

module RedisConfig
  DEFAULT_SENTINEL_PORT = '26379'.freeze

  class << self
    def app
      config
    end

    def config
      @config ||= sentinel? ? sentinel_config : base_config
    end

    def base_config
      {
        url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379'),
        password: ENV.fetch('REDIS_PASSWORD', nil).presence,
        ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
        reconnect_attempts: 2,
        timeout: 1
      }
    end

    def sentinel?
      ENV.fetch('REDIS_SENTINELS', nil).present?
    end

    def sentinel_url_config(sentinel_url)
      host, port = sentinel_url.split(':').map(&:strip)
      config = { host: host, port: port || DEFAULT_SENTINEL_PORT }

      password = ENV.fetch('REDIS_SENTINEL_PASSWORD', base_config[:password])
      config[:password] = password if password.present?

      config
    end

    def sentinel_config
      redis_sentinels = ENV.fetch('REDIS_SENTINELS', '')

      sentinels = redis_sentinels.split(',').map do |sentinel_url|
        sentinel_url_config(sentinel_url)
      end

      master = "redis://#{ENV.fetch('REDIS_SENTINEL_MASTER_NAME', 'mymaster')}"
      base_config.merge({ url: master, sentinels: sentinels })
    end
  end
end
