require 'logger'
require 'byebug'

module Reports
  module Middleware

    class Logging < Faraday::Middleware
      attr_reader :logger

      def initialize(app)
        super(app)
        @logger = Logger.new(STDOUT)
        @logger.formatter = proc { |severity, datetime, program, message| message + "\n" }
      end

      def call(env)
        # Do something with the request
        start_time = Time.now

        # Do something with the response. Do all processing of response only in the on_complete block. This enables middleware to work in parallel mode where requests are asynchronous.
        response = @app.call(env)
        response.on_complete do |response_env|
          duration = Time.now - start_time
          url, method, status = env.url.to_s, env.method, response_env.status
          cached = response_env.response_headers["X-Faraday-Cache-Status"] ? "hit" : "miss"
          logger.debug '-> %s %s %d (%.3f s) %s' % [url, method.to_s.upcase, status, duration, cached]
        end
      end

    end

  end
end