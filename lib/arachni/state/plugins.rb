=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'monitor'

module Arachni
class State

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Plugins

    # @return   [Hash]
    #   Runtime plugin data.
    attr_reader :runtime

    def initialize
        super
        @runtime = {}
    end

    # Registers plugin states.
    #
    # @param    [Arachni::Plugin::Base]    plugin   Instance of a plugin.
    # @param    [Object]    state
    def store( plugin, state )
        @runtime[plugin.shortname.to_sym] = state
    end
    alias :[]= :store

    def []( k )
        @runtime[k.to_sym]
    end

    def dump( directory )
        %w(runtime).each do |type|
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

        %w(runtime).each do |type|
            Dir["#{directory}/#{type}/*"].each do |plugin_directory|
                plugin = File.basename( plugin_directory ).to_sym
                plugins.send(type)[plugin] = Marshal.load( IO.read( plugin_directory ) )
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
