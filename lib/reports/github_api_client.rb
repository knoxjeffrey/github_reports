require 'faraday'
require 'json'
require 'logger'
require 'byebug'
require_relative 'middleware/logging'

module Reports

  class Error < StandardError; end
  class AuthenticationFailure < Error; end
  class Nonexistentuser < Error; end
  class RequestFailer < Error; end
  class RateLimitHit < Error; end

  User = Struct.new(:name, :location, :public_repos)
  Repo = Struct.new(:name, :url)

  VALID_STATUS_CODES = [200, 302, 401, 403, 404, 422]

  class GitHubAPIClient

    attr_reader :github_token, :logger

    def initialize(github_token)
      @github_token = github_token
    end

    def user_info(username)
      headers = {"Authorization" => "token #{github_token}"}
      url = "https://api.github.com/users/#{username}"

      response = connection.get(url, nil, headers) # nil is the query parameters

      check_response_status(username, response)

      data = JSON.parse(response.body)
      User.new(data["name"], data["location"], data["public_repos"])
    end

    def public_repos_for_user(username)
      headers = {"Authorization" => "token #{github_token}"}

      url = "https://api.github.com/users/#{username}/repos"

      response = connection.get(url, nil, headers)

      check_response_status(username, response)

      data = JSON.parse(response.body)
      data.map {|repository| Repo.new(repository["full_name"], repository["url"])}
    end

    def connection
      # Connection objects manage the default properties and the middleware stack for fulfilling an HTTP request.
      @connection ||= Faraday::Connection.new do |builder|
        builder.use Middleware::Logging
        builder.adapter Faraday.default_adapter
      end
    end

    private

    def check_response_status(username, response)
      if VALID_STATUS_CODES.include? response.status
        case response.status
        when 401
          raise AuthenticationFailure, "Authentication Failed. Please set the 'GITHB_TOKEN' environment variable to a valid Github access token "
        when 403
          raise RateLimitHit, "You have hit your rate limit for api calls"
        when 404
          raise Nonexistentuser, "'#{username}' does not exist"
        end
      else
        raise RequestFailer, JSON.parse(response.body)['message']
      end
    end

  end

end
