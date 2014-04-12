=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Report

#
# Provides some common options for the reports.
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Options
    include Component::Options

    # Returns a string option named `outfile`.
    #
    # Default value is:
    #   year-month-day hour.minute.second +timezone.extension
    #
    # @param    [String]    extension     Extension for the outfile.
    # @param    [String]    description   Description of the option.
    #
    # @return   [Arachni::OptString]
    def outfile( extension = '', description = 'Where to save the report.' )
        Options::String.new( 'outfile',
            description: description,
            default:     Time.now.to_s.gsub( ':', '.' ) + extension
        )
    end

    def skip_responses
        Options::Bool.new( 'skip_responses',
             description: "Don't include the bodies of the HTTP " +
                 'responses of the issues in the report' +
                 ' -- will lead to a greatly decreased report file-size.',
             default:     false
        )
    end

    extend self
end


class FormatterManager < Component::Manager
    def paths
        Dir.glob( File.join( "#{@lib}", "*.rb" ) ).reject { |path| helper?( path ) }
    end
end

# An abstract class for the reports, all reports must extend this.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @abstract
class Base < Component::Base
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
        @@formatters[ancestor].load_all if @@formatters[ancestor].empty?

        # run the formatters and gather the formatted data they return
        @@formatters[ancestor].each do |name, formatter|
            plugin_results = plugins[name]
            next if !plugin_results || plugin_results[:results].empty?

            cr = plugin_results.clone
            block.call( cr ) if block_given?
            formatted[name] = formatter.new( auditstore, cr ).run
        end

        formatted
    end

    def outfile
        if File.directory?( options['outfile'] )
            return File.expand_path "#{options['outfile']}/" +
                    "#{self.class.outfile_option.default}"
        end

        options['outfile']
    end

    def skip_responses?
        !!options['skip_responses']
    end

    def self.has_outfile?
        !!outfile_option
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
