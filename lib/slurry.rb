require 'slurry/graphite'
require 'slurry/storage'
require 'slurry/data'

require 'json'
require "redis"
require 'json2graphite'
require 'net/http'
require 'rest_client'

# @author Zach Leslie <xaque208@gmail.com>
#

module Slurry
  module_function

  def flush (server,port,wait=0.1)

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
