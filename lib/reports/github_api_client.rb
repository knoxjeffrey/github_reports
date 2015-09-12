require 'byebug'

require 'faraday'
require_relative 'middleware/logging'
require_relative 'middleware/authentication'
require_relative 'middleware/check_status_code'
require_relative 'middleware/json_parsing'
require_relative 'middleware/cache'
require_relative 'storage/redis'

module Reports

  class Error < StandardError; end
  class AuthenticationFailure < Error; end
  class Nonexistentuser < Error; end
  class Nonexistentrepo < Error; end
  class RequestFailer < Error; end
  class RateLimitHit < Error; end
  class ConfigurationError < Error; end
  class GistCreationFailure < Error; end

  User = Struct.new(:name, :location, :public_repos)
  Repo = Struct.new(:name, :languages)
  Event = Struct.new(:type, :repo_name)

  class GitHubAPIClient

    attr_reader :github_token, :logger

    def initialize
      level = ENV["LOG_LEVEL"]
      @logger = Logger.new(STDOUT)
      @logger.formatter = proc { |severity, datetime, program, message| message + "\n" }
      @logger.level = Logger.const_get(level) if level
    end

    def user_info(username)
      url = "https://api.github.com/users/#{username}"

      response = connection.get(url) # nil is the query parameters

      data = response.body
      User.new(data["name"], data["location"], data["public_repos"])
    end

    def public_repos_for_user(username, forks: forks)
      url = "https://api.github.com/users/#{username}/repos"

      response = connection.get(url)

      repos = response.body

      link_header = response.headers['link']

      if link_header
        while match_data = link_header.match(/<(.*)>; rel="next"/)
          next_page_url = match_data[1]
          response = connection.get(next_page_url)
          link_header = response.headers['link']
          repos += response.body
        end
      end

      repos.map do |repository|
        next if !forks && repository["fork"]

        full_name = repository["full_name"]
        language_url = "https://api.github.com/repos/#{full_name}/languages"
        response = connection.get(language_url)

        Repo.new(repository["full_name"], response.body)
      end

    end

    def public_events_for_user(username)
      url = "https://api.github.com/users/#{username}/events/public"

      response = connection.get(url)

      events = response.body

      link_header = response.headers['link']

      if link_header
        while match_data = link_header.match(/<(.*)>; rel="next"/)
          next_page_url = match_data[1]
          response = connection.get(next_page_url)
          link_header = response.headers['link']
          events += response.body
        end
      end

      events.map { |event_data| Event.new(event_data["type"], event_data["repo"]["name"]) }
    end

    def create_private_gist(description, file, content)
      url = "https://api.github.com/gists"
      body = {
        "description" => "#{description}",
        "public" => false,
        "files" => {
          "#{file}" => {
            "content" => "#{content}"
          }
        }
      }

      response = connection.post(url) do |request|
        request.body = body.to_json
      end

      response.body["html_url"]
    end

    def star_repository(username, repo)
      url = "https://api.github.com/user/starred/#{username}/#{repo}"

      response = connection.put(url) do |request|
        request.headers['Content-Length'] = "0"
      end
    end

    def connection
      ca_path = File.expand_path("~/.mitmproxy/mitmproxy-ca-cert.pem")
      options = { proxy: 'https://localhost:8080',
                  ssl: {ca_file: ca_path},
                  url: "https://api.github.com" }
      # Connection objects manage the default properties and the middleware stack for fulfilling an HTTP request.
      @connection ||= Faraday::Connection.new(options) do |builder|
        builder.use Middleware::CheckStatusCode
        builder.use Middleware::Authentication
        builder.use Middleware::JSONParsing
        builder.use Middleware::Logging
        builder.use Middleware::Cache, Storage::Redis.new

        builder.adapter Faraday.default_adapter
      end
    end

  end

end
