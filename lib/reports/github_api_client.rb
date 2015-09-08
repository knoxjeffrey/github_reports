require 'faraday'
require 'json'
require 'logger'
require 'byebug'

module Reports

  class Error < StandardError; end
  class AuthenticationFailure < Error; end
  class Nonexistentuser < Error; end
  class RequestFailer < Error; end
  class RateLimitHit < Error; end

  User = Struct.new(:name, :location, :public_repos)
  VALID_STATUS_CODES = [200, 302, 401, 403, 404, 422]

  class GitHubAPIClient

    attr_reader :github_token, :logger

    def initialize(github_token)
      @github_token = github_token
      level = ENV["LOG_LEVEL"]
      @logger = Logger.new(STDOUT)
      @logger.formatter = proc do |serverity, time, progname, msg|
        msg + "\n"
      end
    end

    def user_info(username)
      headers = {"Authorization" => "token #{github_token}"}
      url = "https://api.github.com/users/#{username}"

      start_time = Time.now
      response = Faraday.get(url, nil, headers) # nil is the query parameters

      duration = Time.now - start_time

      log_output = '-> %s %s %d (%.3f s)' % [url, 'GET', response.status, duration]
      logger.debug(log_output)

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

      data = JSON.parse(response.body)
      User.new(data["name"], data["location"], data["public_repos"])
    end

  end

end
