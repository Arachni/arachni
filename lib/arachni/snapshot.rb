=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'zip'
require 'fileutils'

require_relative 'data'
require_relative 'state'

module Arachni

# Stores and provides access to the state of the system.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Snapshot

    # {State} error namespace.
    #
    # All {State} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Arachni::Error
    end

class <<self

    # @param    [String]    archive
    #   Location of the archive.
    # @return   [String]
    #   Location of the archive.
    def dump( archive )
        directory = get_temporary_directory

        FileUtils.rm_rf( directory )
        FileUtils.mkdir_p( directory )

        begin
            Data.dump( "#{directory}/data/" )
            State.dump( "#{directory}/state/" )

            compress directory, archive
        ensure
            FileUtils.rm_rf( directory )
        end
    end

    # @param    [String]    archive
    #   Location of the archive.
    # @return   [Snapshot]     `self`
    def load( archive )
        directory = get_temporary_directory

        decompress( archive, directory )

        Data.load( "#{directory}/data/" )
        State.load( "#{directory}/state/" )

        self
    end

    private

    def get_temporary_directory
        "#{Dir.tmpdir}/Arachni_Snapshot_#{Utilities.generate_token}/"
    end

    def decompress( archive, directory )
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
        Zip::File.open( archive, Zip::File::CREATE ) do |zipfile|
            Dir[File.join(directory, '**', '**')].each do |file|
                zipfile.add( file.sub( directory, '' ), file )
            end
        end

        archive
    end

end
end
end
