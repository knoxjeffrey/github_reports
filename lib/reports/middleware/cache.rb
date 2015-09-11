require 'byebug'

module Reports
  module Middleware

    class Cache < Faraday::Middleware

      attr_reader :app
      attr_accessor :storage

      def initialize(app, storage)
        super(app)
        @app = app
        @storage = storage
      end

      def call(env)
        key = env.url.to_s
        cached_response = storage.read(key)

        # If the resource is cached, check that it's fresh (age of cached resource is
        # less than the max permitted age) and then check if it needs revalidated.
        #
        # If it's not fresh, take the value in the cached response ETag header and pass
        # it onto the server in the If-None-Match header. This checks if the resource on
        # the server has changed, even though it is old. If it hasn't changed then the
        # server does not need to send a response body because we have an up to date
        # copy in the cache and therefore just use the cached version.
        if cached_response
          if fresh?(cached_response)
            if !needs_revalidation?(cached_response)
              cached_response.env.response_headers["X-Faraday-Cache-Status"] = "true"
              return cached_response
            end
          else
            env.request_headers["If-None-Match"] = cached_response.headers['ETag']
          end
        end

        response = app.call(env)
        response.on_complete do |response_env|
          if cachable_response?(response_env)
            # If the server responds with 304 Not Modified just update the cached
            # response's Date header and return the cached version
            #
            # Otherwise the server will have returned the full body response which we
            # then cache and return the full response from the server
            if response.status == 304
              #cached_response = storage.read(key)
              cached_response.headers['Date'] = response.headers['Date']
              storage.write(key, cached_response)

              response.env.update(cached_response.env)
            else
              storage.write(key, response)
            end
          end
        end
        response
      end

      def cachable_response?(env)
        env.method == :get && env.response_headers['Cache-Control'] && !env.response_headers['Cache-Control'].include?('no-store')
      end

      def needs_revalidation?(cached_response)
        cached_response.headers['Cache-Control'] == 'no-cache' || cached_response.headers['Cache-Control'] == 'must-validate'
      end

      def fresh?(cached_response)
        age = cached_response_age(cached_response)
        max_age = cached_response_max_age(cached_response)

        if age && max_age # Always stale without these values
          age <= max_age
        end
      end

      def cached_response_age(cached_response)
        date = cached_response.headers['Date']
        if date
          time = Time.httpdate(date)
          (Time.now - time).floor
        end
      end

      def cached_response_max_age(cached_response)
        cache_control = cached_response.headers['Cache-Control']
        if cache_control
          match = cache_control.match(/max\-age=(\d+)/)
          match[1].to_i if match
        end
      end

    end

  end
end