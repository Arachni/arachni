=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class Browser
class Javascript
class TaintTracer

# Represents a stack frame for a JS function call.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Frame

    # @return   [String, nil]
    #   Source of the relevant function.
    attr_accessor :source

    # @return   [String]
    #   Name of the relevant function.
    attr_accessor :function

    # @return   [Array]
    #   Arguments passed to the relevant function.
    attr_accessor :arguments

    # @return   [String, nil]
    #   Location of the file containing the relevant function.
    attr_accessor :url

    # @return   [Integer, nil]
    #   Line number related to the called frame.
    attr_accessor :line

    def initialize( options = {} )
        options.symbolize_keys(false).each do |k, v|
            send( "#{k}=", v )
        end
    end

    def to_h
        instance_variables.inject({}) do |h, iv|
            h[iv.to_s.gsub('@', '').to_sym] = instance_variable_get( iv )
            h
        end
    end

    def hash
        to_h.hash
    end

    def ==( other )
        hash == other.hash
    end

    def to_rpc_data
        to_h
    end

    def self.from_rpc_data( data )
        new data
    end

end

end
end
end
end
