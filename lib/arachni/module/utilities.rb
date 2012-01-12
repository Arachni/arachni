=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

require 'digest/sha1'
require 'cgi'

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
# @version: 0.1.3
#
module Utilities

    def uri_parser
        @@uri_parser ||= URI::Parser.new
    end

    def uri_parse( url )
        uri_parser.parse( url )
    end

    def uri_encode( *args )
        uri_parser.escape( *args )
    end

    def uri_decode( *args )
        uri_parser.unescape( *args )
    end

    #
    # Decodes URLs to reverse multiple encodes and removes NULL characters
    #
    def url_sanitize( url )

        while( url =~ /%[a-fA-F0-9]{2}/ )
            url = ( uri_decode( url ).to_s.unpack( 'A*' )[0] )
        end

        return uri_encode( CGI.unescapeHTML( url ) )
    end

    #
    # Gets path from URL
    #
    # @param   [String]   url
    #
    # @return  [String]   path
    #
    def get_path( url )

        uri  = uri_parser.parse( uri_encode( url ) )
        path = uri.path

        if !File.extname( path ).empty?
            path = File.dirname( path )
        end

        path << '/' if path[-1] != '/'
        return uri.scheme + "://" + uri.host + path
    end

    def seed
        @@seed ||= Digest::SHA2.hexdigest( srand( 1000 ).to_s )
    end

    def normalize_url( url )

        # make sure we're working with the pure form of the URL
        url = url_sanitize( url )

        begin
            normalized = uri_encode( uri_decode( url.to_s ) ).to_s.gsub( '[', '%5B' ).gsub( ']', '%5D' )
        rescue Exception => e
            # ap e
            # ap e.backtrace
            begin
                normalized = uri_encode( uri_decode( url.to_s ) ).to_s
            rescue Exception => e
                # ap e
                # ap e.backtrace
                normalized = url
            end
        end

        #
        # prevent this: http://example.com#fragment
        # from becoming this: http://example.com%23fragment
        #
        begin
            normalized.gsub!( '%23', '#' )
        rescue

        end

        return normalized
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

    def hash_keys_to_str( hash )
        nh = {}
        hash.each_pair {
            |k, v|
            nh[k.to_s] = v
            nh[k.to_s] = hash_keys_to_str( v ) if v.is_a? Hash
        }

        return nh
    end

    #
    # Wraps the "block" in exception handling code and runs it.
    #
    # @param    [Block]
    #
    def exception_jail( raise_exception = true, &block )
        begin
            block.call
        rescue Exception => e
            err_name = !e.to_s.empty? ? e.to_s : e.class.name
            print_error( err_name )
            print_error_backtrace( e )
            raise e if raise_exception
        end
    end

    extend self

end

end
end
