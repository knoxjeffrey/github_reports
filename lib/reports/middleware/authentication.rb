module Reports
  module Middleware

    class Authentication < Faraday::Middleware

      attr_reader :github_token

      def initialize(app)
        super(app)
        @github_token = ENV['GITHUB_TOKEN']
      end

      def call(env)
        env.request_headers["Authorization"] = "token #{github_token}"

        response = @app.call(env)
        response.on_complete do |response_env|

          if response_env.status == 401
            raise AuthenticationFailure, "Authentication Failed. Please set the 'GITHUB_TOKEN' environment variable to a valid Github access token."
          end

        end
      end

    end

  end
end