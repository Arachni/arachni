=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative '../option_parser'

module Arachni
module UI::CLI

class RestoredFramework

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class OptionParser < UI::CLI::OptionParser

    attr_accessor :snapshot_path

    def snapshot
        separator ''
        separator 'Snapshot'

        on( '--snapshot-print-metadata',
            'Show the metadata associated with the specified snapshot.' ) do
            @print_metadata = true
        end
    end

    def print_metadata?
        !!@print_metadata
    end

    def after_parse
        @snapshot_path = ARGV.shift
    end

    def validate
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

    def banner
        "Usage: #{$0} SNAPSHOT"
    end

end
end
end
end
