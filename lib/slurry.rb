require 'json'
require "redis"
require 'json2graphite'
#require 'graphite-util'

module Slurry
  module_function

  # Pull in new data from STDIN
  def funnel
    data = Hash.new

    body = ''
    body += STDIN.read
    data[:hash] = JSON.parse(body)
    data[:time] = Time.now.to_i
    pipe(data)

  end

  # Push that data to redis
  def pipe (hash)
    redis = Redis.new
    redis.lpush('slurry',hash.to_json)
  end

  # Report the contents of the redis server
  def report
    r = Redis.new

    data = Hash.new
    data[:slurry] = Hash.new
    data[:slurry][:waiting] = r.llen('slurry')

    puts data.to_json
  end

  # Dump clean out everything from redis
  def clean
    r = Redis.new

    while r.llen('slurry') > 0 do
      r.rpop('slurry')
    end

  end

  def liaise (server,port,wait=0.1)
    r = Redis.new

    loop do

      # Pull something off the list
      popped = r.brpop('slurry')
      data = JSON.parse(popped[1])

      # Convert the json into graphite useable data
      processed = Json2Graphite.get_graphite(data["hash"], data["time"])
      s = TCPSocket.open(server, port)
      processed.each do |line|
        s.puts(line)
      end
      s.close
      sleep wait
    end

  end

end
