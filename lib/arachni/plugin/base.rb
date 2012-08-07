=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni
module Plugin

#
# Will be extended by plugin formatters which provide plugin data formatting
# for the reports.
#
# Plugin formatters will be in turn ran by [Arachni::Report::Bas#format_plugin_results].
#
#
class Formatter
    # get the output interface
    include Arachni::UI::Output

    attr_reader :results
    attr_reader :description

    def initialize( plugin_data )
        @results     = plugin_data[:results]
        @description = plugin_data[:description]
    end

    def run
    end

end

#
# An abstract class which all plugins must extend.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @abstract
#
class Base
    # I hate keep typing this all the time...
    include Arachni

    # get the output interface
    include Module::Output
    include Module::Utilities

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
        false
    end

    #
    # REQUIRED IF self.distributable? RETURNS 'TRUE'
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
                #                                   option name        required?       description                        default
                # Component::Options::Bool.new( 'print_framework', [ false, 'Do you want to print the framework?', false ] ),
                # Component::Options::String.new( 'my_name_is',    [ false, 'What\'s you name?', 'Tasos' ] ),
            ],
            # specify an execution order group
            # plug-ins will be separated in groups based on this number
            # and be run in the specified order
            #
            # if this option is omitted the plug-in will be run last
            #
            order:       0
        }
    end

    def http
        framework.http
    end

    #
    # Registers the plugin's results with the framework.
    #
    # @param    [Object]    results
    #
    def register_results( results )
        framework.plugins.register_results( self, results )
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
