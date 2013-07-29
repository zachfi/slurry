require 'slurry/storage/redis'

module Slurry
  module Storage
    # Delegates work to default storage method
    def store(hash)
      store_with_redis(hash)
    end

    # Caches the current data into Redis
    def store_with_redis(hash)
      s = Slurry::Data.new(hash)
      Slurry::Storage::Redis.store(s)
    end
  end
end
