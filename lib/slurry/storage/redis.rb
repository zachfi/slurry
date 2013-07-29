require 'redis'

module Slurry::Storage::Redis
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

end
