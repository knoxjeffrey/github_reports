require 'redis'

module Reports
  module Storage

    class Redis

      attr_accessor :redis

      def initialize(redis=::Redis.new)
        @redis = redis
      end

      def read(key)
        value = redis.get(key)
        Marshal.load(value) if value
      end

      def write(key, value)
        redis.set(key, Marshal.dump(value))
      end

      def flush
        redis.flushall
      end

    end

  end
end