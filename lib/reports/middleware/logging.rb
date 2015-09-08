require 'logger'

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
        @app.call(env).on_complete do
          duration = Time.now - start_time
          url, method, status = env.url.to_s, env.method, env.status
          logger.debug '-> %s %s %d (%.3f s)' % [url, method.to_s.upcase, status, duration]
        end
      end

    end

  end
end