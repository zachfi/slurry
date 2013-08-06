#require 'slurry/storage/redis'

module Slurry
  module Storage
    module_function

    def store(data)
      r = Redis.new
      r.lpush('slurry', data.to_json)
    end

    # Throw away everything in the redis key
    def clean
      r = Redis.new
      while r.llen('slurry') > 0 do
        r.rpop('slurry')
      end
    end

    # Report the contents of the redis server
    def report
      r = Redis.new
      pp r.class
      data = Hash.new
      data[:slurry] = Hash.new
      data[:slurry][:waiting] = r.llen('slurry')
      data
    end

    def inspect
      r = Redis.new
      data = r.lrange("slurry", 0, -1)
      data
    end

    # Delegates work to default storage method
    #def store(hash)
    #  store_with_redis(hash)
    #end

    ## Caches the current data into Redis
    #def store_with_redis(hash)
    #  s = Slurry::Data.new(hash)
    #  Slurry::Storage::Redis.store(s)
    #end
  end
end
