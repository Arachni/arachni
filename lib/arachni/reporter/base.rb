=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'options'
require_relative 'formatter_manager'

module Arachni
module Reporter

# An abstract class for the reporters, all reporters must extend this.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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

    # @param    [Report]  report
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

    # Runs plugin formatters for the running report and returns a hash with the
    # prepared/formatted results.
    def format_plugin_results( run = true, &block )
        # Add the PluginFormatters module to the report.
        eval "class #{self.class}; module PluginFormatters end; end"

        # Get the path to the report file, we're assuming it's the one who
        # called us.
        report_path = caller_path(1)

        # Prepare the directory of the formatters for the running report.
        lib = File.dirname( report_path ) + '/plugin_formatters/' +
            File.basename( report_path, '.rb' ) +  '/'

        @@formatters ||= {}

        # Initialize a new component manager to handle the plugin formatters.
        @@formatters[shortname] ||= FormatterManager.new(
            lib, self.class.const_get( :PluginFormatters )
        )

        @@formatters[shortname].load_all if @@formatters[shortname].empty?

        formatted = {}
        @@formatters[shortname].each do |name, formatter_klass|
            name    = name.to_sym
            results = report.plugins[name]

            next if !results || results[:results].empty?

            formatter = formatter_klass.new( self, report, results )

            block.call( name, formatter ) if block_given?

            next if !run
            formatted[name] = formatter.run
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
