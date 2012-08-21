require 'json'
require "redis"
require 'json2graphite'

module Slurry
  module_function

  class Graphite
    def initialize(server,port)
      @server, @port = server, port
      @s = TCPSocket.open(server,port)
    end

    def send (target,value,time)
      line = [target,value,time].join(" ")
      puts line
      @s.puts(line)
    end

    def close
      @s.close
    end
  end


  # Reads from STDIN, expects json hash of just data
  def funnel
    data = Hash.new

    body = ''
    body += STDIN.read
    jsondata = JSON.parse(body)
    exit 1 unless jsondata.is_a? Hash
    data[:hash] = JSON.parse(body)
    data[:time] = Time.now.to_i
    pipe(data)

  end

  # Receives a hash formatted like so
  #  {:time=>1345411779,
  #  :collectd=>
  #     {"myhostname"=>{"ntpd"=>-0.00142014}}}
  #
  # Pushes data into redis
  def pipe (hash)
    redis = Redis.new
    redis.lpush('slurry',hash.to_json)
  end

  def push_to_redis (data, time=Time.now.to_i)
    hash = Hash.new
    hash[:data] = data
    hash[:time] = time
    r = Redis.new
    r.lpush('slurry', hash.to_json)
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

    data = Hash.new
    data = r.lrange("slurry", 0, -1)

    data

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

    #loop do

    while r.llen('slurry') > 0 do


      # Pull something off the list
      popped = r.brpop('slurry')
      data = JSON.parse(popped[1])

      # Convert the json into graphite useable data
      processed = Json2Graphite.get_graphite(data["hash"], data["time"])
      #s = TCPSocket.open(server, port)
      processed.each do |line|
        puts line
      #  s.puts(line)
      end
      #s.close
      #sleep wait
    end

  end


  def runonce (server,port,wait=0.1)

    # This method operates on a different form of hash than the method above.
    # I am not yet sure how to solve this bit.
    #
    r = Redis.new
    report = Hash.new
    report[:processed] = 0

    g = Slurry::Graphite.new(server,port)

    #loop do
    while r.llen('slurry') > 0 do

      # Pull something off the list
      popped = r.rpop('slurry')
      d = JSON.parse(popped)

      graphite = Json2Graphite.get_graphite(d["data"], d["time"])

      # Convert the json into graphite useable data
      graphite.each do |d|
        #pp d
        target = "#{d[:target]}"
        value  = "#{d[:value]}"
        time   = "#{d[:time]}"
        #puts d.to_json
        #processed = Json2Graphite.get_graphite(d)
        #processed.each do |line|
          g.send(target,value, time)
          report[:processed] += 1
        #end
      end
      #sleep wait
    end
    g.close
    report.to_json

  end

end
