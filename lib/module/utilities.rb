=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Module


#
# Utilities class
#
# Includes some useful methods for the system, the modules etc...
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
module Utilities

    #
    # Gets path from URL
    #
    # @param   [String]   url
    #
    # @return  [String]   path
    #
    def get_path( url )
        uri = URI( URI.escape( url ) )
        path = File.dirname( uri.path )
        path << '/' if path[-1] != '/'
        return uri.scheme + "://" + uri.host + path
    end

    def seed
        @@seed ||= Digest::SHA2.hexdigest( srand( 1000 ).to_s )
    end

    def normalize_url( url )
        URI.encode( URI.decode( url.to_s ) ).to_s.gsub( '[', '%5B' ).gsub( ']', '%5D' )
    end

    #
    # Gets module data files from 'modules/[modtype]/[modname]/[filename]'
    #
    # @param    [String]    filename filename, without the path
    # @param    [Block]     the block to be passed each line as it's read
    #
    def read_file( filename, &block )

        # the path of the module that called us
        mod_path = block.source_location[0]

        # the name of the module that called us
        mod_name = File.basename( mod_path, ".rb")

        # the path to the module's data file directory
        path    = File.expand_path( File.dirname( mod_path ) ) +
            '/' + mod_name + '/'

        file = File.open( path + '/' + filename ).each {
            |line|
            yield line.strip
        }

        file.close

    end

    #
    # Wraps the "block" in exception handling code and runs it.
    #
    # @param    [Block]
    #
    def exception_jail( &block )
        begin
            block.call
        rescue Exception => e
            print_error( e.to_s )
            print_debug_backtrace( e )
            raise e
        end
    end

    extend self

end

end
end
