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
module Report

#
# Provides some common options for the reports
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Options
    include Component::Options

    #
    # Returns a string option named 'outfile'.
    #
    # Default value is:
    #   year-month-day hour.minute.second +timezone.extension
    #
    # @param    [String]    ext     extension for the outfile
    # @param    [String]    desc    description of the option
    #
    # @return   [Arachni::OptString]
    #
    def outfile( ext = '', desc = 'Where to save the report.' )
        Arachni::Component::Options::String.new( 'outfile', [ false, desc,
            Time.now.to_s.gsub( ':', '.' ) + ext ] )
    end

    extend self
end


class FormatterManager < Component::Manager

    def paths
        Dir.glob( File.join( "#{@lib}", "*.rb" ) ).reject { |path| helper?( path ) }
    end

end

#
# An abstract class for the reports, all reports must extend this.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @abstract
#
class Base
    # I hate keep typing this all the time...
    include Arachni

    # get the output interface
    include UI::Output
    include Module::Utilities

    include Report

    # where to report false positives info about this should be included in all templates
    REPORT_FP = 'http://github.com/Arachni/arachni/issues'

    module PluginFormatters
    end

    attr_reader :options
    attr_reader :auditstore

    #
    # @param    [AuditStore]  auditstore
    # @param    [Hash]        options       options passed to the report
    #
    def initialize( auditstore, options )
        @auditstore = auditstore
        @options    = options
    end

    #
    # REQUIRED
    #
    def run
    end

    def outfile
        options['outfile']
    end

    #
    # Runs plugin formatters for the running report and returns a hash
    # with the prepared/formatted results.
    #
    # @param    [AuditStore#plugins]      plugins   plugin data/results
    #
    def format_plugin_results( plugins = auditstore.plugins, &block )
        formatted = {}
        return formatted if !plugins

        # get the object that extends this class (i.e. the running report)
        ancestor = self.class.ancestors[0]

        # add the PluginFormatters module to the report
        eval "class #{ancestor}; module PluginFormatters end; end"

        # get the path to the report file
        # this is a very bad way to do it...
        report_path = ::Kernel.caller.first.split( ':' ).first

        # prepare the directory of the formatters for the running report
        lib = File.dirname( report_path ) + '/plugin_formatters/' + File.basename( report_path, '.rb' ) +  '/'

        @@formatters ||= {}

        # initialize a new component manager to handle the plugin formatters
        @@formatters[ancestor] ||= FormatterManager.new( lib, ancestor.const_get( 'PluginFormatters' ) )

        # load all the formatters
        @@formatters[ancestor].load( ['*'] ) if @@formatters[ancestor].empty?

        # run the formatters and gather the formatted data they return
        @@formatters[ancestor].each do |name, formatter|
            plugin_results = plugins[name]
            next if !plugin_results || plugin_results[:results].empty?

            exception_jail( false ) {
                cr = plugin_results.clone
                block.call( cr ) if block_given?
                formatted[name] = formatter.new( cr ).run
            }
        end

        formatted
    end

    def self.has_outfile?
        (info[:options] || {}).each { |opt| return true if opt.name == Options.outfile.name }
        false
    end
    def has_outfile?
        self.class.has_outfile?
    end

    #
    # REQUIRED
    #
    # Do not omit any of the info.
    #
    def self.info
        {
            name:        'Report abstract class.',
            options:     [
                #                    option name    required?       description                         default
                # Arachni::OptBool.new( 'html',    [ false, 'Include the HTML responses in the report?', true ] ),
                # Arachni::OptBool.new( 'headers', [ false, 'Include the headers in the report?', true ] ),
            ],
            description: %q{This class should be extended by all reports.},
            author:      'zapotek',
            version:     '0.1.1',
        }
    end

end

end
end
