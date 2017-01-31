=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative '../option_parser'

module Arachni
module UI::CLI

class RestoredFramework

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class OptionParser < UI::CLI::OptionParser

    attr_accessor :snapshot_path

    def timeout
        separator ''
        separator 'Timeout'

        on( '--timeout HOURS:MINUTES:SECONDS',
            'Stop the scan after the given duration is exceeded.'
        ) do |time|
            @timeout = Arachni::Utilities.hms_to_seconds( time )
        end
    end

    def timeout_suspend
        on( '--timeout-suspend',
            'Suspend after the timeout.',
            'You can use the generated file to resume the scan with the \'arachni_restore\' executable.'
        ) do
            @timeout_suspend = true
        end
    end

    def timeout_suspend?
        !!@timeout_suspend
    end

    def get_timeout
        @timeout
    end

    def snapshot
        separator ''
        separator 'Snapshot'

        on( '--snapshot-print-metadata',
            'Show the metadata associated with the specified snapshot.' ) do
            @print_metadata = true
        end

        on( '--snapshot-save-path PATH', String,
            'Directory or file path where to store the scan snapshot.',
            'You can use the generated file to resume the scan at a later time ' +
                "with the 'arachni_restore' executable."
        ) do |path|
            options.snapshot.save_path = path
        end
    end

    def report
        separator ''
        separator 'Report'

        on( '--report-save-path PATH', String,
            'Directory or file path where to store the scan report.',
            "You can use the generated file to create reports in several " +
                "formats with the 'arachni_report' executable."
        ) do |path|
            options.datastore.report_path = path
        end
    end


    def print_metadata?
        !!@print_metadata
    end

    def after_parse
        @snapshot_path = ARGV.shift
    end

    def validate
        validate_timeout
        validate_report_path
        validate_snapshot_path
        validate_snapshot_save_path
    end

    def validate_timeout
        return if !@timeout || @timeout > 0

        print_bad 'Invalid timeout value.'
        exit 1
    end

    def validate_snapshot_path
        if !@snapshot_path
            print_error 'No snapshot file provided.'
            exit 1
        end

        @snapshot_path = File.expand_path( @snapshot_path )

        if !File.exists?( @snapshot_path )
            print_error "Snapshot does not exist: #{@snapshot_path}"
            exit 1
        end

        begin
            Snapshot.read_metadata @snapshot_path
        rescue Snapshot::Error::InvalidFile => e
            print_error e.to_s
            exit 1
        end
    end

    def validate_snapshot_save_path
        snapshot_path = options.snapshot.save_path
        return if valid_save_path?( snapshot_path )

        print_error "Snapshot path does not exist: #{snapshot_path}"
        exit 1
    end

    def validate_report_path
        report_path = options.datastore.report_path
        return if valid_save_path?( report_path )

        print_error "Report path does not exist: #{report_path}"
        exit 1
    end

    def valid_save_path?( path )
        !path || File.directory?( path ) || !path.end_with?( '/' )
    end

    def banner
        "Usage: #{$0} SNAPSHOT"
    end

end
end
end
end
