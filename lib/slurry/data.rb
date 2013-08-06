require 'slurry'

module Slurry
  class Data

    attr_reader :data

    # Data is a hash
    def initialize(initdata)
      @initdata = initdata
      @data = Hash.new
      encap!
    end

    def data
      @data
    end

    private

    #
    # Encapsulate the data in a new hash under the key :data and
    # adds a timestamp to the new hash at key :time
    #
    def encap!
      unless proper?
        timestamp
        @data[:data] = @initdata
      end
    end

    def decap
      @data[:data]
    end

    # Wraps received hash in new hash with timestamp applied.
    #
    # @param [Hash] hash
    # @parah [Int] time time of the recorded event
    #
    def timestamp (time=Time.now.to_i)
      @data[:time] = time
    end

    # Check to see if the data hash is in its correct state for
    # storage.  Returns bool
    #
    def proper?
      @data and @data[:time] and @data[:data]
    end

  end
end
