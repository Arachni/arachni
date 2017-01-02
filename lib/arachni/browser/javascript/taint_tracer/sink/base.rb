=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Browser
class Javascript
class TaintTracer
class Sink

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Base

    # @return   [Array<Frame>]
    #   Stacktrace.
    attr_accessor :trace

    def initialize( options = {} )
        options.my_symbolize_keys(false).each do |k, v|
            send( "#{k}=", v )
        end

        @trace ||= []
    end

    def to_h
        instance_variables.inject({}) do |h, iv|
            h[iv.to_s.gsub('@', '').to_sym] = instance_variable_get( iv )
            h
        end.merge( trace: trace.map(&:to_h))
    end
    def to_hash
        to_h
    end

    def hash
        to_h.hash
    end

    def ==( other )
        hash == other.hash
    end

    def to_rpc_data
        to_h.merge( trace: trace.map(&:to_rpc_data) )
    end

    def self.from_rpc_data( data )
        data['trace'] = data['trace'].map { |d| Frame.from_rpc_data( d ) }
        new data
    end

end

end
end
end
end
end
