=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
class Browser
class Javascript

# Provides access to the `TaintTracer` JS interface, with extra Ruby-side
# functionality to format results of functions that return sink data.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class TaintTracer < Proxy

    require_relative 'taint_tracer/frame'
    require_relative 'taint_tracer/sink/base'
    require_relative 'taint_tracer/sink/data_flow'
    require_relative 'taint_tracer/sink/execution_flow'

    # @param    [Javascript]    javascript
    #   Active {Javascript} interface.
    def initialize( javascript )
        super javascript, 'TaintTracer'
    end

    # @!method  data_flow_sinks
    #
    #   @return [Array<Sink::DataFlow>]
    #       JS data flow sink data.

    # @!method  flush_data_flow_sinks
    #
    #   @return [Array<Sink::DataFlow>]
    #       Returns and clears {#data_flow_sinks}.

    %w(data_flow_sinks flush_data_flow_sinks).each do |m|
        define_method m do
            prepare_data_flow_sink_data call( m )
        end
    end

    # @!method  debugging_data
    #
    #   @return [Array<Sink::ExecutionFlow>]
    #       JS debugging information.

    # @!method  execution_flow_sinks
    #
    #   @return [Array<Sink::ExecutionFlow>]
    #       JS execution flow sink data.

    # @!method  flush_execution_flow_sinks
    #
    #   @return [Array<Sink::ExecutionFlow>]
    #       Returns and clears {#execution_flow_sinks}.

    %w(debugging_data execution_flow_sinks flush_execution_flow_sinks).each do |m|
        define_method m do
            prepare_execution_flow_sink_data call( m )
        end
    end

    def class
        TaintTracer
    end

    private

    def prepare_data_flow_sink_data( data )
        return [] if !data

        data.map do |entry|
            Sink::DataFlow.new( (entry['data'] || {}).symbolize_keys( false ).merge(
                trace: [entry['trace']].flatten.compact.
                          map { |h| Frame.new h.symbolize_keys( false ) }
                )
            )
        end
    end

    def prepare_execution_flow_sink_data( data )
        return [] if !data

        data.map do |entry|
            Sink::ExecutionFlow.new( entry.merge(
                trace: [entry['trace']].flatten.compact.
                           map { |h| Frame.new h.symbolize_keys( false ) }
                )
            )
        end
    end

end

end
end
end
