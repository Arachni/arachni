=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative '../option_parser'

module Arachni
module UI::CLI

class Report

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class OptionParser < UI::CLI::OptionParser

    attr_reader :framework

    # @return   [Hash{<String, Symbol> => Hash{String => String}}]
    #   Reports to load, by name, as keys and their options as values.
    #
    # @see Reports
    # @see Report::Base
    # @see Report::Manager
    attr_accessor :reports

    attr_accessor :report_path

    def initialize(*)
        super

        @framework = Arachni::Framework.new
        @reports   = {}
    end

    def report
        separator ''
        separator 'Reports'

        on( '--reports-list [PATTERN]', Regexp,
            'List available reports based on the provided pattern.',
            '(If no pattern is provided all reports will be listed.)'
        ) do |pattern|
            list_reports( framework.list_reports( pattern ) )
            exit
        end

        on( "--report 'REPORT:OPTION=VALUE,OPTION2=VALUE2'",
            "REPORT is the name of the report as displayed by '--reports-list'.",
            "(Reports are referenced by their filename without the '.rb' " +
                "extension, use '--list-reports' to list all.)",
            '(Default: stdout)',
            '(Can be used multiple times.)'
        ) do |report|
            prepare_component_options( reports, report )
        end
    end

    def after_parse
        @report_path = ARGV.shift
    end

    def validate
        if !@report_path
            print_error 'No report file provided.'
            exit 1
        end

        @report_path = File.expand_path( @report_path )

        if !File.exists?( @report_path )
            print_error "Report does not exist: #{@report_path}"
            exit 1
        end

        if reports.any?
            begin
                framework.reports.load( reports.keys )
            rescue Component::Error::NotFound => e
                print_error e
                print_info 'Available reports are:'
                print_info framework.reports.available.join( ', ' )
                print_line
                print_info 'Use the \'--reports-list\' parameter to see a' <<
                               ' detailed list of all available reports.'
                exit 1
            ensure
                framework.reports.clear
            end
        end
    end

    def banner
        "Usage: #{$0} REPORT"
    end

end
end
end
end
