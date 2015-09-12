module Reports
  module Middleware

    class CheckStatusCode < Faraday::Middleware

      VALID_STATUS_CODES = [200, 201, 204, 302, 401, 403, 404, 422]

      def initialize(app)
        super(app)
      end

      def call(env)
        response = @app.call(env)
        response.on_complete do |response_env|

          if VALID_STATUS_CODES.include? response_env.status
            case response.status
            when 403
              raise RateLimitHit, "You have hit your rate limit for api calls"
            when 404
              if response_env.method.to_s == "put"
                raise Nonexistentrepo, "'The repo #{parse_repo(env.url)}' does not exist"
              else
                raise Nonexistentuser, "'#{parse_username(env.url)}' does not exist"
              end
            when 422
              raise GistCreationFailure, "Sorry, your gist was not created"
            end
          else
            raise RequestFailer, JSON.parse(response.body)['message']
          end

        end
      end

      private

      def parse_username(url)
        string_after_users = /^https:\/\/api.github.com\/users\/(.*)/.match(url.to_s)
        # removes any directories after the username
        # eg https://api.github.com/users/knoxjeffrey/repos
        string_after_users[1].split("/").first
      end

      def parse_repo(url)
        string_after_starred = /^https:\/\/api.github.com\/user\/starred\/(.*)/.match(url.to_s)
        # eg https://api.github.com/user/starred/knoxjeffrey/github_reports
        string_after_starred[1]
      end

    end

  end
end