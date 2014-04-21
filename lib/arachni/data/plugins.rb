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

    def statistics
        {
            names: @results.keys
        }
    end

    # Registers plugin results.
    #
    # @param    [Arachni::Plugin::Base]    plugin   Instance of a plugin.
    # @param    [Object]    results
    def store( plugin, results )
        synchronize do
            @results[plugin.shortname.to_sym] = plugin.class.info.merge(
                results: results
            )
        end
    end

    # Merges the {#results} with the provided `results` by delegating to each
    # {Plugin::Base.distributable?} plugin's {Plugin::Base.merge} method.
    #
    # @param    [Plugin:Manager]     plugins
    # @param    [Array]               results
    def merge_results( plugins, results )
        begin
            plugin_info      = {}
            isolated_results = {}
            merged           = {}

            (results + [@results]).each do |result|
                result.each do |name, res|
                    next if !res
                    name = name.to_sym

                    isolated_results[name] ||= []
                    isolated_results[name] << (res['results'] || res[:results])

                    plugin_info[name] ||= res.reject { |k, v| k.to_s == 'results' }.
                        symbolize_keys(false)
                end
            end

            isolated_results.each do |plugin, res|
                merged_result = plugins[plugin].distributable? ?
                    plugins[plugin].merge( res ) : res[0]

                merged[plugin] = plugin_info[plugin].merge( results: merged_result )
            end

            @results = merged
        rescue => e
            print_error "Could not merge plugin results, will only use local ones: #{e}"
            print_error_backtrace e
        end

        @results
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
