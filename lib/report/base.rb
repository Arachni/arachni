=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Report

#
# Arachni::Report::Base class
#
# An abstract class for the reports.<br/>
# All reports must extend this.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
# @abstract
#
class Base

    # get the output interface
    include Arachni::UI::Output

    # where to report false positives <br/>
    # info about this should be included in all templates
    REPORT_FP = 'http://github.com/Zapotek/arachni/issues'

    module PluginFormatters

    end

    #
    # REQUIRED
    #
    def run( )

    end

    #
    # Runs plugin formatters for the running report and returns a hash
    # with the prepared/formatted results.
    #
    # @param    [AuditStore#plugins]      plugins   plugin data/results
    #
    def format_plugin_results( plugins )

        # get the object that extends this class (i.e. the running report)
        ancestor = self.class.ancestors[0]

        # add the PluginFormatters module to the report
        eval( "class " + ancestor.to_s + "\n module  PluginFormatters end \n end" )

        # get the path to the report file
        # this is a very bad way to do it...
        report_path = ::Kernel.caller[0].match( /^(.+?):(\d+)(?::in `(.*)')?/ )[1]

        # prepare the directory of the formatters for the running report
        lib = File.dirname( report_path ) + '/plugin_formatters/' + File.basename( report_path, '.rb' ) +  '/'

        # initialize a new component manager to handle the plugin formatters
        formatters = ::Arachni::ComponentManager.new( lib, ancestor.const_get( 'PluginFormatters' ) )
        formatters.include_formatters!

        # load all the formatters
        formatters.load( ['*'] )

        # run the formatters and gather the formatted data they return
        formatted = {}
        formatters.each_pair {
            |name, formatter|
            plugin_results = plugins[name]
            next if !plugin_results || plugin_results[:results].empty?

            formatted[name] = formatter.new( plugin_results ).run
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
            :version        => '0.1',
        }
    end

end

end
end
