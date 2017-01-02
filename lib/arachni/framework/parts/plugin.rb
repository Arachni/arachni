=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Framework
module Parts

# Provides a {Arachni::Plugin::Manager} and related helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
                next if patterns && !@plugins.matches_globs?( path, patterns )

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

end

end
end
end
