=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Report

#
# Provides some common options for the reports
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
module Options

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
        Arachni::OptString.new( 'outfile', [ false, desc,
            Time.now.to_s.gsub( ':', '.' ) + ext ] )
    end

    extend self
end


class FormatterManager < ComponentManager

    def paths
        cpaths = paths = Dir.glob( File.join( "#{@lib}", "*.rb" ) )
        return paths.reject { |path| helper?( path ) }
    end

end

#
# Arachni::Report::Base class
#
# An abstract class for the reports.<br/>
# All reports must extend this.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
# @abstract
#
class Base

    # get the output interface
    include Arachni::UI::Output
    include Arachni::Module::Utilities

    # where to report false positives <br/>
    # info about this should be included in all templates
    REPORT_FP = 'http://github.com/Arachni/arachni/issues'

    module PluginFormatters

    end

    #
    # @param    [AuditStore]  audit_store
    # @param    [Hash]        options       options passed to the report
    #
    def initialize( audit_store, options )
        @audit_store   = audit_store
        @options       = options
    end

    #
    # REQUIRED
    #
    def run

    end

    #
    # Runs plugin formatters for the running report and returns a hash
    # with the prepared/formatted results.
    #
    # @param    [AuditStore#plugins]      plugins   plugin data/results
    #
    def format_plugin_results( plugins )
        formatted = {}
        return formatted if !plugins

        # get the object that extends this class (i.e. the running report)
        ancestor = self.class.ancestors[0]

        # add the PluginFormatters module to the report
        eval( "class " + ancestor.to_s + "\n module  PluginFormatters end \n end" )

        # get the path to the report file
        # this is a very bad way to do it...
        report_path = ::Kernel.caller[0].match( /^(.+?):(\d+)(?::in `(.*)')?/ )[1]

        # prepare the directory of the formatters for the running report
        lib = File.dirname( report_path ) + '/plugin_formatters/' + File.basename( report_path, '.rb' ) +  '/'

        @@formatters ||= {}

        # initialize a new component manager to handle the plugin formatters
        @@formatters[ancestor] ||= FormatterManager.new( lib, ancestor.const_get( 'PluginFormatters' ) )

        # load all the formatters
        @@formatters[ancestor].load( ['*'] ) if @@formatters[ancestor].empty?

        # run the formatters and gather the formatted data they return
        @@formatters[ancestor].each_pair {
            |name, formatter|
            plugin_results = plugins[name]
            next if !plugin_results || plugin_results[:results].empty?

            exception_jail( false ) {
                formatted[name] = formatter.new( plugin_results.deep_clone ).run
            }
        }

        return formatted
    end

    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            :name           => 'Report abstract class.',
            :options        => [
                #                    option name    required?       description                         default
                # Arachni::OptBool.new( 'html',    [ false, 'Include the HTML responses in the report?', true ] ),
                # Arachni::OptBool.new( 'headers', [ false, 'Include the headers in the report?', true ] ),
            ],
            :description    => %q{This class should be extended by all reports.},
            :author         => 'zapotek',
            :version        => '0.1.1',
        }
    end

end

end
end
