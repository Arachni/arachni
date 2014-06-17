=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class Browser
class Javascript
class TaintTracer
class Sink

# Represents an intercepted JS call due to {#tainted} {#arguments}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class DataFlow < Base

    # @return   [Frame::CalledFunction]
    #   Relevant function.
    attr_accessor :function

    # @return   [String]
    #   Name of the object containing {#function}.
    attr_accessor :object

    # @return   [Integer]
    #   Index for the tainted argument in {#arguments}.
    attr_accessor :tainted_argument_index

    # @return   [Object]
    #   Tainted value of {#tainted_argument_value}, located by traversing it
    #   recursively.
    attr_accessor :tainted_value

    # @return   [String]
    #   Active taint.
    attr_accessor :taint

    def initialize( options = {} )
        if options[:function].is_a? Hash
            @function = Frame::CalledFunction.new( options.delete(:function) )
        end

        super
    end

    # @return   [String, nil]
    #   Value of the tainted argument.
    def tainted_argument_value
        return if !function.arguments
        function.arguments[tainted_argument_index]
    end

    # @return   [String, nil]
    #   Name of the tainted argument.
    def tainted_argument_name
        return if !function.signature_arguments
        function.signature_arguments[tainted_argument_index]
    end

    def to_h
        super.merge( function: function.to_h )
    end

    def to_rpc_data
        to_h.merge( function: function.to_rpc_data )
    end

    def self.from_rpc_data( data )
        data['function'] = Frame::CalledFunction.from_rpc_data( data['function'] )
        super data
    end

end

end
end
end
end
end
