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
# Includes some useful methods for the system, the modules etc...
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Utilities

    def uri_parser
        @@uri_parser ||= URI::Parser.new
    end

    def uri_parse( url )
        begin
            uri_parser.parse( url )
        rescue URI::InvalidURIError
            uri_parser.parse( WEBrick::HTTPUtils.escape( url ) )
        end
    end

    def uri_encode( *args )
        uri_parser.escape( *args )
    end

    def uri_decode( *args )
        uri_parser.unescape( *args )
    end

    def forms_from_response( *args )
        Arachni::Parser::Element::Form.from_response( *args )
    end

    def forms_from_document( *args )
        Arachni::Parser::Element::Form.from_document( *args )
    end

    def links_from_response( *args )
        Arachni::Parser::Element::Link.from_response( *args )
    end

    def links_from_document( *args )
        Arachni::Parser::Element::Link.from_document( *args )
    end

    def parse_url_vars( *args )
        Arachni::Parser::Element::Link.parse_query_vars( *args )
    end

    def cookies_from_response( *args )
        Arachni::Parser::Element::Cookie.from_response( *args )
    end

    def cookies_from_document( *args )
        Arachni::Parser::Element::Cookie.from_document( *args )
    end

    def cookies_from_file( *args )
        Arachni::Parser::Element::Cookie.from_file( *args )
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

        uri_str = uri.scheme + "://" + uri.host
        uri_str += ':' + uri.port.to_s if uri.port != 80
        uri_str += path
    end
    def seed
        @@seed ||= Digest::SHA2.hexdigest( srand( 1000 ).to_s )
    end

    def normalize_url( url )

        normalizer = Proc.new {
            |url|
            uri_encode(
                uri_decode( url )
                .encode( 'UTF-8',
                    undef:   :replace,
                    invalid: :replace
                ),
                Regexp.union( uri_parser.regexp[:UNSAFE], /[\[\]\\'" {};\|\$%]/ )
            )
        }

        begin
            begin
                normalized = normalizer.call( url_sanitize( url ) )
            rescue Exception => e
                # ap e
                # ap e.backtrace

                normalized = normalizer.call( url )
            end
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

        # prevent this: http://example.com#fragment
        # from becoming this: http://example.com%23fragment
        begin
            normalized.gsub!( '%23', '#' )
        rescue
        end

        # ap normalized
        return normalized
    end

    #
    # Extracts the domain from a URI object
    #
    # @param [URI] url
    #
    # @return [String]
    #
    def extract_domain( url )
        return false if !url.host

        splits = url.host.split( /\./ )

        return splits.first if splits.size == 1

        splits[-2] + "." + splits[-1]
    end

    def path_too_deep?( url )
        opts = Arachni::Options.instance

        if opts.depth_limit > 0 && (opts.depth_limit + 1) <= URI(url.to_s).path.count( '/' )
            return true
        else
            return false
        end
    end

    #
    # Returns +true+ if *uri* is in the same domain as the page, returns
    # +false+ otherwise
    #
    def path_in_domain?( uri, ref_url = Arachni::Options.instance.url.to_s )
        return true if !ref_url || ref_url.empty?

        opts = Arachni::Options.instance
        curi = uri_parse( normalize_url( uri.to_s ) )

        if opts.follow_subdomains
            return extract_domain( curi ) == extract_domain( uri_parse( ref_url.to_s ) )
        end

        return curi.host == uri_parse( normalize_url( ref_url.to_s ) ).host
    end

    def exclude_path?( url )
        opts = Arachni::Options.instance
        opts.exclude.each {
            |pattern|
            return true if url.to_s =~ pattern
        }

        return false
    end

    def include_path?( url )
        opts = Arachni::Options.instance
        return true if opts.include.empty?

        opts.include.each {
            |pattern|
            pattern = Regexp.new( pattern ) if pattern.is_a?( String )
            return true if url.to_s =~ pattern
        }
        return false
    end

    def skip_path?( path )
        return true if !path

        begin
            return true if !include_path?( path )
            return true if exclude_path?( path )
            return true if path_too_deep?( path )
            return true if !path_in_domain?( path )
            false
        rescue
            true
        end
    end

    #
    # Converts relative URL *link* into an absolute URL based on the
    # location of the page
    #
    # @param    [String]    relative_url
    # @param    [String]    reference_url    absoslute url to use as a reference
    #
    # @return [String]
    #
    def to_absolute( relative_url, reference_url = Arachni::Options.instance.url.to_s )
        begin
            relative_url = normalize_url( relative_url )
            if uri_parser.parse( relative_url ).host
                return relative_url
            end
        rescue Exception => e
            # ap e
            # ap e.backtrace
            return nil
        end

        begin
            # remove anchor
            relative_url = uri_encode( relative_url.to_s.gsub( /#[a-zA-Z0-9_-]*$/,'' ) )

            base_url = uri_parser.parse( reference_url )

            relative = uri_parser.parse( relative_url )
            absolute = base_url.merge( relative )

            absolute.path = '/' if absolute.path && absolute.path.empty?

            return absolute.to_s
        rescue Exception => e
            # ap e
            # ap e.backtrace
            return nil
        end
    end

    #
    # Gets module data files from 'modules/[modtype]/[modname]/[filename]'
    #
    # @param    [String]    filename  filename, without the path
    # @param    [Block]     block     the block to be passed each line as it's read
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
            begin
                err_name = !e.to_s.empty? ? e.to_s : e.class.name
                print_error( err_name )
                print_error_backtrace( e )
            rescue
            end
            raise e if raise_exception
        end
    end

    extend self

end

end
end
