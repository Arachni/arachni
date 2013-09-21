=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'tmpdir'

module Arachni
module Support::Database

#
# Base class for Database data structures
#
# Provides helper methods for data structures to be implemented related to
# objecting dumping, loading, unique filename generation, etc.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @abstract
#
class Base

    # @param    [Object]    serializer
    #   Any object that responds to 'dump' and 'load'.
    def initialize( serializer = Marshal )
        @serializer = serializer
    end

    private

    #
    # Dumps the object to a unique file and returns its path.
    #
    # The path can be used as a reference to the original value
    # by way of passing it to load().
    #
    # @param    [Object]    obj
    #
    # @return   [String]    filepath
    #
    def dump( obj, &block )
        f = File.open( get_unique_filename, 'w' )

        serialized = serialize( obj )
        f.write( serialized )

        block.call( serialized ) if block_given?

        f.path
    ensure
        f.close
    end

    #
    # Loads the object stored in filepath.
    #
    # @param    [String]    filepath
    #
    # @return   [Object]
    #
    def load( filepath )
        unserialize( IO.read( filepath ) )
    end

    #
    # Deletes a file.
    #
    # @param    [String]    filepath
    #
    def delete_file( filepath )
        File.delete( filepath ) if File.exist?( filepath )
    end

    #
    # Loads the object in file and then removes it from the file-system.
    #
    # @param    [String]    filepath
    #
    # @return   [Object]
    #
    def load_and_delete_file( filepath )
        obj = load( filepath )
        delete_file( filepath )
        return obj
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
        while( File.exist?( path = generate_filename ) );end
        return path
    end

    def generate_filename
        s = ""
        10.times { s << ( 65 + rand( 26 ) ) }
        ( Dir.tmpdir + "/#{self.class.name}_" + s ).gsub( '::', '_' )
    end

end

end
end
