=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative '../option_parser'

module Arachni
module UI::CLI

class Reproduce

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class OptionParser < UI::CLI::OptionParser

    attr_accessor :report
    attr_accessor :report_path
    attr_accessor :updated_report_path

    attr_accessor :issues
    attr_accessor :issue_digests

    def initialize
        @issues = []
    end

    def report_options
        separator ''
        separator 'Report'

        on( '--report-save-path PATH', String,
            'Directory or file path where to store the updated report ' <<
            'including only reproduced issues.',
            'You can use the generated file to create reports in several ' +
                "formats with the 'arachni_reporter' executable."
        ) do |path|
            @updated_report_path = path
        end
    end

    def after_parse
        @report_path   = ARGV.shift
        @issue_digests = ARGV.dup
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

        begin
            @report = Report.load( @report_path )
        rescue => e
            print_error "Could not load report: #{@report_path}"
            print_error "Because: [#{e.class}] #{e}"
            exit 1
        end

        if @issue_digests.any?
            @issues = @report.issues.
                select { |i| @issue_digests.include? i.digest.to_s }

            if @issues.empty?
                print_error "Could not find any issues for digests: #{@issue_digests.join(' ')}"
                exit 1
            end

            @issue_digests = @issue_digests.map(&:to_i)
        end
    end

    def banner
        "Usage: #{$0} REPORT [ISSUE_DIGEST_1 ISSUE_DIGEST_2 ...]"
    end

end
end
end
end
