=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class State

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Plugins

    # @return   [Hash]
    #   Runtime plugin data.
    attr_reader :runtime

    def initialize
        @runtime = {}
    end

    def statistics
        {
            names: @runtime.keys
        }
    end

    # Registers plugin states.
    #
    # @param    [String,Symbol]    plugin
    #   Plugin {Component::Base.shortname}.
    #
    # @param    [Object]    state
    def store( plugin, state )
        @runtime[plugin.to_sym] = state
    end
    alias :[]= :store

    # @param    [String,Symbol]    plugin
    #   Plugin {Component::Base.shortname}.
    #
    # @return    [Object]
    def []( plugin )
        @runtime[plugin.to_sym]
    end

    # @param    [String,Symbol]    plugin
    #   Plugin {Component::Base.shortname}.
    #
    # @return    [Object]
    def delete( plugin )
        @runtime.delete( plugin.to_sym )
    end

    # @param    [String,Symbol]    plugin
    #   Plugin {Component::Base.shortname}.
    #
    # @return    [Bool]
    def include?( plugin )
        @runtime.include?( plugin.to_sym )
    end

    def dump( directory )
        %w(runtime).each do |type|
            send(type).each do |plugin, data|
                result_directory = "#{directory}/#{type}/"
                FileUtils.mkdir_p( result_directory )

                IO.binwrite( "#{result_directory}/#{plugin}", Marshal.dump( data ) )
            end
        end
    end

    def self.load( directory )
        plugins = new

        %w(runtime).each do |type|
            Dir["#{directory}/#{type}/*"].each do |plugin_directory|
                plugin = File.basename( plugin_directory ).to_sym
                plugins.send(type)[plugin] = Marshal.load( IO.binread( plugin_directory ) )
            end
        end

        plugins
    end

    def clear
        @runtime.clear
    end

end
end
end
