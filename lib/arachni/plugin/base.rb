=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Plugin

# Will be extended by plugin formatters which provide plugin data formatting
# for the reports.
#
# Plugin formatters will be in turn ran by [Arachni::Report::Bas#format_plugin_results].
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Formatter
    # get the output interface
    include UI::Output

    attr_reader :auditstore
    attr_reader :results
    attr_reader :description

    def initialize( auditstore, plugin_data )
        @auditstore  = auditstore
        @results     = plugin_data[:results]
        @description = plugin_data[:description]
    end

    def run
    end

end

# An abstract class which all plugins must extend.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Base < Component::Base
    include Component

    attr_reader :options
    attr_reader :framework

    #
    # @param    [Arachni::Framework]    framework
    # @param    [Hash]        options    options passed to the plugin
    #
    def initialize( framework, options )
        @framework = framework
        @options   = options

        self.class.initialize_mutex
    end

    #
    # OPTIONAL
    #
    def prepare
    end

    #
    # REQUIRED
    #
    def run
    end

    #
    # OPTIONAL
    #
    def clean_up
    end

    #
    # OPTIONAL
    #
    # Only used when in Grid mode.
    #
    # Should the plug-in be distributed
    # across all instances or only run by the master
    # prior to any distributed operations?
    #
    # For example, if a plug-in dynamically modifies the framework options
    # in any way and wants these changes to be identical
    # across instances this method should return 'false'.
    #
    def self.distributable?
        @distributable ||= false
    end

    # Should the plug-in be distributed
    # across all instances or only run by the master
    # prior to any distributed operations?
    def self.distributable
        @distributable = true
    end
    # Should the plug-in be distributed
    # across all instances or only run by the master
    # prior to any distributed operations?
    def self.is_distributable
        distributable
    end

    #
    # REQUIRED IF self.distributable? returns 'true' and the plugins stores results.
    #
    # Only used when in Grid mode.
    #
    # Merges an array of results as gathered by the plug-in when run
    # by multiple instances.
    #
    def self.merge( results )
    end

    #
    # Should return an array of plugin related gem dependencies.
    #
    # @return   [Array]
    #
    def self.gems
        []
    end

    #
    # REQUIRED
    #
    # Do not omit any of the info.
    #
    def self.info
        {
            name:        'Abstract plugin class',
            description: %q{Abstract plugin class.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            options:     [
                #                       option name        required?       description                        default
                # Options::Bool.new( 'print_framework', [ false, 'Do you want to print the framework?', false ] ),
                # Options::String.new( 'my_name_is',    [ false, 'What\'s you name?', 'Tasos' ] ),
            ],
            # specify an execution priority group
            # plug-ins will be separated in groups based on this number
            # and lowest will be first
            #
            # if this option is omitted the plug-in will be run last
            #
            priority:    0
        }
    end

    def session
        framework.session
    end

    def http
        framework.http
    end

    #
    # Provides a thread-safe way to run the queued HTTP requests.
    #
    def http_run
        synchronize { http.run }
    end

    #
    # Provides plugin-wide synchronization.
    #
    def self.synchronize( &block )
        @mutex.synchronize( &block )
    end
    def synchronize( &block )
        self.class.synchronize( &block )
    end

    def self.initialize_mutex
        @mutex ||= Mutex.new
    end

    #
    # Registers the plugin's results with the framework.
    #
    # @param    [Object]    results
    #
    def register_results( results )
        State.plugins.store( self, results )
    end

    #
    # Will block until the scan finishes.
    #
    def wait_while_framework_running
        ::IO.select( nil, nil, nil, 1 ) while( framework.running? )
    end

end

end
end
