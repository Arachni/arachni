=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Framework
module Parts

module Plugin

    # @return   [Arachni::Plugin::Manager]
    attr_reader :plugins

    def initialize
        super
        @plugins = Arachni::Plugin::Manager.new( self )
    end

    # @return    [Array<Hash>]
    #   Information about all available {Plugins}.
    def list_plugins( patterns = nil )
        loaded = @plugins.loaded

        begin
            @plugins.clear
            @plugins.available.map do |plugin|
                path = @plugins.name_to_path( plugin )
                next if !list_plugin?( path, patterns )

                @plugins[plugin].info.merge(
                    options:   @plugins[plugin].info[:options] || [],
                    shortname: plugin,
                    path:      path,
                    author:    [@plugins[plugin].info[:author]].
                                   flatten.map { |a| a.strip }
                )
            end.compact
        ensure
            @plugins.clear
            @plugins.load loaded
        end
    end

    private

    def list_plugin?( path, patterns = nil )
        regexp_array_match( patterns, path )
    end

end

end
end
end
