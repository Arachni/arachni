=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'monitor'

module Arachni
class State

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Plugins
    include MonitorMixin

    # @return   [Hash<Symbol=>Hash>]
    #   Plugin results.
    attr_reader :results

    # @return   [Hash]
    #   Runtime plugin data.
    attr_reader :runtime

    def initialize
        super

        @results = {}
        @runtime = {}
    end

    # Registers plugin results.
    #
    # @param    [Arachni::Plugin::Base]    plugin   Instance of a plugin.
    # @param    [Object]    results
    def store( plugin, results )
        synchronize do
            @results[plugin.shortname.to_sym] = plugin.class.info.merge(results: results)
        end
    end

    # Merges the {#results} with the provided `results` by delegating to each
    # {Plugin::Base.distributable?} plugin's {Plugin::Base.merge} method.
    #
    # @param    [Plugin:Manager]     plugins
    # @param    [Array]     results
    def merge_results( plugins, results )
        info = {}
        formatted = {}

        results << @results
        results.each do |result|
            result.each do |name, res|
                next if !res

                formatted[name] ||= []
                formatted[name] << res[:results]

                info[name] = res.reject{ |k, v| k == :results } if !info[name]
            end
        end

        merged = {}
        formatted.each do |plugin, c_results|
            if !plugins[plugin].distributable?
                res = c_results[0]
            else
                res = plugins[plugin].merge( c_results )
            end
            merged[plugin] = info[plugin].merge( results: res )
        end

        @results = merged
    end

    def clear
        @results.clear
        @runtime.clear
    end

end
end
end
