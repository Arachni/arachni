=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class Browser

class Javascript

# Provides access to the `TaintTracer` JS interface, with extra Ruby-side
# functionality to format results of functions that return sink data.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class TaintTracer < Proxy

    # @param    [Javascript]    javascript  Active {Javascript} interface.
    def initialize( javascript )
        super javascript, 'TaintTracer'
    end

    %w(debugging_data execution_flow_sink data_flow_sink flush_execution_flow_sink
        flush_data_flow_sink).each do |m|
        define_method m do
            prepare_sink_data call( m )
        end
    end

    def class
        TaintTracer
    end

    private

    def prepare_sink_data( sink_data )
        return [] if !sink_data

        sink_data.map do |entry|
            {
                data:  entry['data'],
                trace: [entry['trace']].flatten.compact.
                           map { |h| h.symbolize_keys( false ) }
            }
        end
    end

end
end
end
end
