require 'json'
require "redis"
require 'json2graphite'

# @author Zach Leslie <zach@puppetlabs.com>
#
module Slurry
  module_function

  # Handles connection details to the graphite server.
  class Graphite

    # Opens a socket with the specified graphite server.
    #
    # @param [String] server
    # @param [String] port
    def initialize(server,port)
      @server, @port = server, port
      @s = TCPSocket.open(server,port)
    end

    # Puts the graphite formatted string into the open socket.
    #
    # @param [String] target the graphite formatted target in dotted notion
    # @param [String] value the value of the target
    # @param [String] time the time that the sample was taken
    def send (target,value,time)
      line = [target,value,time].join(" ")
      @s.puts(line)
    end

    # Closes the open socket to the graphite server.
    #
    def close
      @s.close
    end
  end


  # Wraps received hash in new hash with timestamp applied.
  #
  # @param [Hash] hash
  # @parah [Int] time time of the recorded event
  #
  def timestamp (hash, time=Time.now.to_i)
    data = Hash.new
    data[:data] = hash
    data[:time] = time
    data
  end


  # Reads from STDIN, expects json hash of just data.
  # Creates new hash the original hash as the value of key :hash and the current unix time as key :time.  Calls method pipe() with resulting hash.
  # {
  #   :hash => { <hash read from STDIN> },
  #   :time => <current unix time> 
  #  }
  #
  def funnel
    body = ''
    body += STDIN.read
    jsondata = JSON.parse(body)
    raise "jsondata is not of class Hash.  Is #{jsondata.class}" unless jsondata.is_a? Hash
    pipe(timestamp(jsondata))
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

  def liaise (server,port,wait=0.01)
    r = Redis.new

    loop do

      # Pull something off the list
      popped = r.brpop('slurry')
      d = JSON.parse(popped)

      raise "key 'data' not found in popped hash" unless d["data"]
      raise "key 'time' not found in popped hash" unless d["time"]

      # Convert the json into graphite useable data
      graphite = Json2Graphite.get_graphite(d["data"], d["time"])
      graphite.each do |d|
        target = d[:target].to_s
        value  = d[:value].to_s
        time   = d[:time].to_s
        puts [target,value,time].join(' ')
      end
      #sleep wait
    end

  end


  def runonce (server,port,wait=0.1)

    r = Redis.new           # open a new conection to redis
    report = Hash.new       # initialize the report
    report[:processed] = 0  # we've not processed any items yet

    # open a socket with the graphite server
    g = Slurry::Graphite.new(server,port)


    # process every object in the list called 'slurry'
    while r.llen('slurry') > 0 do

      # pop the next object from the list
      popped = r.rpop('slurry')
      d = JSON.parse(popped)

      # make syre the data we are about to use at least exists
      raise "key 'data' not found in popped hash" unless d["data"]
      raise "key 'time' not found in popped hash" unless d["time"]


      # convert the object we popped into a graphite object
      graphite = Json2Graphite.get_graphite(d["data"], d["time"])

      # break the graphite object down into useable bits
      graphite.each do |d|
        # Make use of the values in the object
        target = d[:target].to_s
        value  = d[:value].to_s
        time   = d[:time].to_s

        # push the data to the open graphite socket
        g.send(target,value, time)
        # record the transaction
        report[:processed] += 1
      end
      #sleep wait
    end
    # close up the connection to graphite
    g.close

    # return the report in json format
    report.to_json

  end

end
