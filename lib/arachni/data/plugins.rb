=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'monitor'

module Arachni
class Data

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Plugins
    include UI::Output
    include MonitorMixin

    # @return   [Hash<Symbol=>Hash>]
    #   Plugin results.
    attr_reader :results

    def initialize
        super

        @results = {}
    end

    def statistics
        {
            names: @results.keys
        }
    end

    # Registers plugin results.
    #
    # @param    [Arachni::Plugin::Base]    plugin
    #   Instance of a plugin.
    # @param    [Object]    results
    def store( plugin, results )
        synchronize do
            @results[plugin.shortname.to_sym] = plugin.info.merge( results: results )
        end
    end

    # Merges the {#results} with the provided `results` by delegating to each
    # {Plugin::Base.distributable?} plugin's {Plugin::Base.merge} method.
    #
    # @param    [Plugin:Manager]     plugins
    # @param    [Array]               results
    def merge_results( plugins, results )
        isolated_results = {}

        (results + [@results]).each do |result|
            result.each do |name, res|
                next if !res
                name = name.to_sym

                isolated_results[name] ||= []
                isolated_results[name] << (res['results'] || res[:results])
            end
        end

        isolated_results.each do |plugin, res|
            next if !plugins[plugin].distributable?

            begin
                store( plugins[plugin], plugins[plugin].merge( res ) )
            rescue => e
                print_error "Could not merge plugin results for plugin '#{plugin}', " +
                                "will only use local ones: #{e}"
                print_error_backtrace e
            end
        end

        nil
    end

    def dump( directory )
        %w(results).each do |type|
            send(type).each do |plugin, data|
                result_directory = "#{directory}/#{type}/"
                FileUtils.mkdir_p( result_directory )

                IO.binwrite( "#{result_directory}/#{plugin}", Marshal.dump( data ) )
            end
        end
    end

    def self.load( directory )
        plugins = new

        %w(results).each do |type|
            Dir["#{directory}/#{type}/*"].each do |plugin_directory|
                plugin = File.basename( plugin_directory ).to_sym
                plugins.send(type)[plugin] = Marshal.load( IO.binread( plugin_directory ) )
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
