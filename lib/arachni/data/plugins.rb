=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'monitor'

module Arachni
class Data

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Plugins
    include MonitorMixin

    # @return   [Hash<Symbol=>Hash>]
    #   Plugin results.
    attr_reader :results

    def initialize
        super

        @results = {}
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

    def dump( directory )
        %w(results).each do |type|
            send(type).each do |plugin, data|
                result_directory = "#{directory}/#{type}/"
                FileUtils.mkdir_p( result_directory )

                File.open( "#{result_directory}/#{plugin}", 'w' ) do |f|
                    f.write Marshal.dump( data )
                end
            end
        end
    end

    def self.load( directory )
        plugins = new

        %w(results).each do |type|
            Dir["#{directory}/#{type}/*"].each do |plugin_directory|
                plugin = File.basename( plugin_directory ).to_sym
                plugins.send(type)[plugin] = Marshal.load( IO.read( plugin_directory ) )
            end
        end

        plugins
    end

    def clear
        @results.clear
    end

end
end
end
