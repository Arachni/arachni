=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'frame/called_function'

module Arachni
class Browser
class Javascript
class TaintTracer

# Represents a stack frame for a JS function call.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Frame

    # @return   [CalledFunction]
    #   Relevant function.
    attr_accessor :function

    # @return   [String, nil]
    #   Location of the file associated with the called frame.
    attr_accessor :url

    # @return   [Integer, nil]
    #   Line number related to the called frame.
    attr_accessor :line

    def initialize( options = {} )
        if options[:function].is_a? Hash
            @function = CalledFunction.new( options.delete(:function) )
        end

        options.my_symbolize_keys(false).each do |k, v|
            send( "#{k}=", v )
        end
    end

    def to_h
        instance_variables.inject({}) do |h, iv|
            h[iv.to_s.gsub('@', '').to_sym] = instance_variable_get( iv )
            h
        end.merge( function: function.to_h )
    end
    alias :to_hash :to_h

    def hash
        to_h.hash
    end

    def ==( other )
        hash == other.hash
    end

    def to_rpc_data
        to_h.merge( function: function.to_rpc_data )
    end

    def self.from_rpc_data( data )
        data['function'] = Frame::CalledFunction.from_rpc_data( data['function'] )
        new data
    end

end

end
end
end
end
