=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Support::Database

# Base class for Database data structures
#
# Provides helper methods for data structures to be implemented related to
# objecting dumping, loading, unique filename generation, etc.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @abstract
class Base

    # @param    [Object]    serializer
    #   Any object that responds to 'dump' and 'load'.
    def initialize( serializer = Marshal )
        @serializer       = serializer
        @filename_counter = 0
    end

    private

    # Dumps the object to a unique file and returns its path.
    #
    # The path can be used as a reference to the original value
    # by way of passing it to load().
    #
    # @param    [Object]    obj
    #
    # @return   [String]
    #   Filepath
    def dump( obj, &block )
        File.open( get_unique_filename, 'wb' ) do |f|
            serialized = serialize( obj )
            f.write( serialized )

            block.call( serialized ) if block_given?

            f.path
        end
    end

    # Loads the object stored in filepath.
    #
    # @param    [String]    filepath
    #
    # @return   [Object]
    def load( filepath )
        unserialize( IO.binread( filepath ) )
    end

    # Deletes a file.
    #
    # @param    [String]    filepath
    def delete_file( filepath )
        File.delete( filepath ) if File.exist?( filepath )
    end

    # Loads the object in file and then removes it from the file-system.
    #
    # @param    [String]    filepath
    #
    # @return   [Object]
    def load_and_delete_file( filepath )
        obj = load( filepath )
        delete_file( filepath )
        obj
    end

    def serialize( obj )
        serializer.dump( obj )
    end

    def unserialize( obj )
        serializer.load( obj )
    end

    def serializer
        @serializer
    end

    def get_unique_filename
        {} while File.exist?( path = generate_filename )
        path
    end

    def generate_filename
        # Should be unique enough...
        "#{Options.paths.tmpdir}/#{self.class.name}_#{Process.pid}_#{object_id}_#{@filename_counter}".gsub( '::', '_' )
    ensure
        @filename_counter += 1
    end

end

end
end
