=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'formatter'

module Arachni
module Plugin

# An abstract class which all plugins must extend.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @abstract
class Base < Component::Base
    include Component
    include MonitorMixin

    # @return   [Hash]
    #   Plugin options.
    attr_reader :options

    # @return   [Framework]
    attr_reader :framework

    # @param    [Framework]   framework
    # @param    [Hash]        options
    #   Options to pass to the plugin.
    def initialize( framework, options )
        @framework = framework
        @options   = options
    end

    # @note **OPTIONAL**
    #
    # Gets called right after the plugin is initialized and is used to prepare
    # its data or setup hooks.
    #
    # This method should not block as the system will wait for it to return prior
    # to progressing.
    #
    # @abstract
    def prepare
    end

    # @note **OPTIONAL**
    #
    # Gets called instead of {#prepare} when restoring a suspended plugin.
    # If no {#restore} method has been defined, {#prepare} will be called instead.
    #
    # @param   [Object] state    State to restore.
    #
    # @see #suspend
    # @abstract
    def restore( state = nil )
    end

    # @note **REQUIRED**
    #
    # Gets called right after {#prepare} and delivers the plugin payload.
    #
    # This method will be ran in its own thread, in parallel to any other system
    # operation. However, once its job is done, the system will wait for this
    # method to return prior to exiting.
    #
    # @abstract
    def run
    end

    # @note **OPTIONAL**
    #
    # Gets called right after {#run} and is used for generic clean-up.
    #
    # @abstract
    def clean_up
    end

    # @note **OPTIONAL**
    #
    # Gets called right before killing the plugin and should return state data
    # to be {Arachni::State::Plugins#store stored} and passed to {#restore}.
    #
    # @return   [Object]    State to store.
    #
    # @see #restore
    # @abstract
    def suspend
    end

    # Pauses the {#framework}.
    def framework_pause
        @pause_id ||= framework.pause( false )
    end

    # Aborts the {#framework}.
    def framework_abort
        Thread.new do
            framework.abort
        end
    end

    # Resumes the {#framework}.
    def framework_resume
        return if !@pause_id
        framework.resume @pause_id
    end

    # @note **OPTIONAL**
    #
    # Only used when in Grid mode.
    #
    # Should the plug-in be distributed across all instances or only run by the
    # master prior to any distributed operations?
    #
    # For example, if a plug-in dynamically modifies the framework options in
    # any way and wants these changes to be identical across instances this
    # method should return `false`.
    def self.distributable?
        @distributable ||= false
    end

    # Should the plug-in be distributed across all instances or only run by the
    # master prior to any distributed operations?
    def self.distributable
        @distributable = true
    end

    # Should the plug-in be distributed across all instances or only run by the
    # master prior to any distributed operations?
    def self.is_distributable
        distributable
    end

    # @note **REQUIRED** if {.distributable?} returns `true` and the plugin
    #   {#register_results registers results}.
    #
    # Merges an array of results as gathered by the plug-in when ran by multiple
    # instances.
    def self.merge( results )
    end

    # Should return an array of plugin related gem dependencies.
    #
    # @return   [Array]
    def self.gems
        []
    end

    # REQUIRED
    #
    # @return   [Hash]
    # @abstract
    def self.info
        {
            name:        'Abstract plugin class',
            description: %q{Abstract plugin class.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
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
    def info
        self.class.info
    end

    def session
        framework.session
    end

    def http
        framework.http
    end

    def browser_cluster
        framework.browser_cluster
    end

    def with_browser( &block )
        browser_cluster.with_browser( &block )
    end

    # Registers the plugin's results to {Data::Plugins}.
    #
    # @param    [Object]    results
    def register_results( results )
        Data.plugins.store( self, results )
    end

    # Will block until the scan finishes.
    def wait_while_framework_running
        sleep 0.1 while framework.running?
    end

end

end
end
