=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'options'
require_relative 'formatter_manager'

module Arachni
module Reporter

# An abstract class for the reporters, all reporters must extend this.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @abstract
class Base < Component::Base
    include Reporter

    # Where to report false positives.
    REPORT_FP = 'http://github.com/Arachni/arachni/issues'

    module PluginFormatters
    end

    attr_reader :options
    attr_reader :report

    # @param    [ScanReport]  report
    # @param    [Hash]        options
    #   Options to pass to the report.
    def initialize( report, options )
        @report  = report
        @options = options
    end

    # @note **REQUIRED**
    #
    # @abstract
    def run
    end

    # Runs plugin formatters for the running report and returns a hash
    # with the prepared/formatted results.
    #
    # @param    [ScanReport#plugins]      plugins
    #   Plugin data/results.
    def format_plugin_results( plugins = report.plugins, &block )
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
        lib = File.dirname( report_path ) + '/plugin_formatters/' +
            File.basename( report_path, '.rb' ) +  '/'

        @@formatters ||= {}

        # initialize a new component manager to handle the plugin formatters
        @@formatters[ancestor] ||= FormatterManager.new(
            lib, ancestor.const_get( 'PluginFormatters' )
        )

        # load all the formatters
        @@formatters[ancestor].load_all if @@formatters[ancestor].empty?

        # run the formatters and gather the formatted data they return
        @@formatters[ancestor].each do |name, formatter|
            plugin_results = plugins[name.to_sym]
            next if !plugin_results || plugin_results[:results].empty?

            cr = plugin_results.clone
            block.call( cr ) if block_given?
            formatted[name] = formatter.new( report, cr ).run
        end

        formatted
    end

    def outfile
        if File.directory?( options[:outfile] )
            return File.expand_path "#{options[:outfile]}/" +
                    "#{self.class.outfile_option.default}"
        end

        options[:outfile]
    end

    def skip_responses?
        !!options[:skip_responses]
    end

    def self.has_outfile?
        !!outfile_option
    end
    def has_outfile?
        self.class.has_outfile?
    end

    # @note **REQUIRED**
    #
    # Do not omit any of the info.
    def self.info
        {
            name:        'Reporter abstract class.',
            options:     [],
            description: %q{This class should be extended by all reports.},
            author:      'zapotek',
            version:     '0.1.1',
        }
    end

    def self.outfile_option
        (info[:options] || {}).find { |opt| opt.name == Options.outfile.name }
    end
end

end
end
