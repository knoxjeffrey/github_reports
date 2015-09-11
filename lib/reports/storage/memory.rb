module Reports
  module Storage

    class Memory

      attr_accessor :hash

      def initialize(hash = {})
        @hash = hash
      end

      # Use Marshal.load to deserialize the value when reading from the cache
      def read(key)
        # use the key to get the serialized value from the hash
        serialized_value = hash[key]
        # Deserialize the value
        Marshal.load(serialized_value) if serialized_value
      end

      # Use Marshal.dump to serialize the value when saving into the cache
      #
      # There are several advantages to serializing the response before we save into
      # the cache.  Now we only need to save and retrieve strings which allows us to
      # use many tools such as Redis.  A lot more flexible because the tools don't need to
      # rely on a Ruby object, just a string
      def write(key, value)
        serialized_value = Marshal.dump(value)
        hash[key]= serialized_value
      end

    end

  end
end