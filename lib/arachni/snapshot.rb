=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'zip'
require 'fileutils'

require_relative 'data'
require_relative 'state'

module Arachni

# Stores and provides access to the state of the system.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Snapshot

    # {Snapshot} error namespace.
    #
    # All {Snapshot} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Arachni::Error

        # Raised when trying to read an invalid snapshot file.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class InvalidFile < Error
        end
    end

class <<self

    # @return   [Hash]
    #   Metadata associated with the {.load loaded} snapshot.
    attr_accessor :metadata

    # @return   [String]
    #   Location of the {.load loaded} snapshot.
    attr_accessor :location

    def reset
        @metadata = nil
        @location = nil
    end

    # @return   [Bool]
    #   `true` if this is a restored snapshot, `false` otherwise.
    def restored?
        !!location
    end

    # @return   [Hash]
    #   Snapshot summary information.
    def summary
        {
            data:  Data.statistics,
            state: State.statistics
        }
    end

    # @param    [String]    location
    #   Location of the snapshot.
    #
    # @return   [String]
    #   Location of the snapshot.
    def dump( location )
        FileUtils.rm_rf( location )

        directory = get_temporary_directory

        FileUtils.rm_rf( directory )
        FileUtils.mkdir_p( directory )

        begin
            Data.dump( "#{directory}/data/" )
            State.dump( "#{directory}/state/" )

            compress directory, location

            # Append metadata to the end of the file.
            metadata = Marshal.dump( prepare_metadata )
            File.open( location, 'ab' ) do |f|
                f.write [metadata, metadata.size].pack( 'a*N' )
            end

            location
        ensure
            FileUtils.rm_rf( directory )
        end
    end

    # @param    [String]    snapshot
    #   Location of the snapshot to load.
    #
    # @return   [Snapshot]
    #   `self`
    #
    # @raise    [Error::InvalidFile]
    #   When trying to read an invalid file.
    def load( snapshot )
        directory = get_temporary_directory

        @location = snapshot
        @metadata = read_metadata( snapshot )

        extract( snapshot, directory )

        Data.load( "#{directory}/data/" )
        State.load( "#{directory}/state/" )

        self
    end

    # @param    [String]    snapshot
    #   Location of the snapshot.
    #
    # @return   [Hash]
    #   Metadata associated with the given snapshot.
    #
    # @raise    [Error::InvalidFile]
    #   When trying to read an invalid file.
    def read_metadata( snapshot )
        File.open( snapshot, 'rb' ) do |f|
            f.seek -4, IO::SEEK_END
            metadata_size = f.read( 4 ).unpack( 'N' ).first

            f.seek -metadata_size-4, IO::SEEK_END
            Marshal.load( f.read( metadata_size ) )
        end
    rescue => e
        ne = Error::InvalidFile.new( "Invalid snapshot: #{snapshot} (#{e})" )
        ne.set_backtrace e.backtrace
        raise ne
    end

    private

    def prepare_metadata
        {
            timestamp: Time.now,
            version:   Arachni::VERSION,
            summary:   summary
        }
    end

    def get_temporary_directory
        "#{Options.paths.tmpdir}/Arachni_Snapshot_#{Utilities.generate_token}/"
    end

    def extract( archive, directory )
        Zip::File.open( archive ) do |zip_file|
            zip_file.each do |f|
                f_path = File.join( directory, f.name )
                FileUtils.mkdir_p( File.dirname( f_path ) )
                zip_file.extract( f, f_path ) unless File.exist?( f_path )
            end
        end

        directory
    end

    def compress( directory, archive )
        # Globs on Windows don't accept \ as a separator since it's an escape character.
        directory = directory.gsub( '\\', '/' ) + '/'
        directory.gsub!( /\/+/, '/' )

        Zip::File.open( archive, Zip::File::CREATE ) do |zipfile|
            Dir[directory + '**/**'].each do |file|
                zipfile.add( file.sub( directory, '' ), file )
            end
        end

        archive
    end

end

reset
end
end
