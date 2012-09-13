module Slurry
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

    # Close the open socket to the graphite server.
    def close
      @s.close
    end

  end
end

