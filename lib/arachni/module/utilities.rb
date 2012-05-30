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

require 'addressable/uri'
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

    #
    # @param    [String]    url     URL to parse
    #
    # @return   [Addressable::URI]
    #
    def uri_parse( url )
        return if !url
        @@uri_parse_cache ||= {}
        return @@uri_parse_cache[url].dup if @@uri_parse_cache.include?( url )

        @@uri_parse_cache[url] = Addressable::URI.parse( url )
        @@uri_parse_cache[url].dup
    end

    #
    # URL encodes a string.
    #
    # @param [String, #to_str] string   The URI component to encode.
    # @param [String, Regexp] bad_characters    class of characters to encode
    #                                               formatted as a regexp
    #
    # @return   [String]    encoded string
    #
    def uri_encode( string, bad_characters = nil )
        Addressable::URI.encode_component( *[string, bad_characters].compact )
    end

    #
    # URL decodes a string.
    #
    # @param [String, #to_str] string   The URI component to encode.
    #
    # @return   [String]    decoded string
    #
    def uri_decode( string )
        Addressable::URI.unencode( string )
    end

    # @see Arachni::Parser::Element::Form.from_response
    def forms_from_response( *args )
        Arachni::Parser::Element::Form.from_response( *args )
    end

    # @see Arachni::Parser::Element::Form.from_document
    def forms_from_document( *args )
        Arachni::Parser::Element::Form.from_document( *args )
    end

    # @see Arachni::Parser::Element::Link.from_response
    def links_from_response( *args )
        Arachni::Parser::Element::Link.from_response( *args )
    end

    # @see Arachni::Parser::Element::Link.from_document
    def links_from_document( *args )
        Arachni::Parser::Element::Link.from_document( *args )
    end

    # @see Arachni::Parser::Element::Link.parse_query_vars
    def parse_url_vars( *args )
        Arachni::Parser::Element::Link.parse_query_vars( *args )
    end

    # @see Arachni::Parser::Element::Cookie.from_response
    def cookies_from_response( *args )
        Arachni::Parser::Element::Cookie.from_response( *args )
    end

    # @see Arachni::Parser::Element::Cookie.from_document
    def cookies_from_document( *args )
        Arachni::Parser::Element::Cookie.from_document( *args )
    end

    # @see Arachni::Parser::Element::Cookie.from_file
    def cookies_from_file( *args )
        Arachni::Parser::Element::Cookie.from_file( *args )
    end

    #
    # @param   [String]   url
    #
    # @return  [String]   path  full URL up to the path component,
    #                           no resource, query etc.
    #
    def get_path( url )
        uri  = uri_parse( normalize_url( url ) )
        path = uri.path

        if !File.extname( path ).empty?
            path = File.dirname( path )
        end

        path << '/' if path[-1] != '/'

        uri_str = uri.scheme + "://" + uri.host
        uri_str += ':' + uri.port.to_s if uri.port && uri.port != 80
        uri_str + path
    end

    # @return   [String]    random HEX (SHA2) string
    def seed
        @@seed ||= Digest::SHA2.hexdigest( srand( 1000 ).to_s )
    end

    #
    # @param    [String]    url
    #
    # @return   [String]    normalized URL
    #
    def normalize_url( url )
        return if !url

        url = url.encode( 'UTF-8', undef: :replace, invalid: :replace )
        begin
            url = uri_decode( url ) while url =~ /%[a-fA-F0-9]{2}/
        rescue
        end

        @@normalize_url_cache ||= {}
        return @@normalize_url_cache[url].dup if @@normalize_url_cache.include?( url.dup )

        escaped = Addressable::URI.encode( url )
        p  = uri_parse( escaped )

        p.scheme = p.scheme.downcase if p.scheme
        p.host   = p.host.downcase if p.host
        p.port   = nil unless p.port != 80

        if p.host && !p.host.empty?
            p.path = p.path && !p.path.empty? ? p.path.gsub(/\/+/, '/') : '/'
        end

        p.fragment = nil

        @@normalize_url_cache[url] = p.to_s

        #addr = Addressable::URI.parse( url ).normalize.to_s
        #if addr != p.to_s
        #    ap '~~~'
        #    ap p
        #    ap url
        #    ap addr
        #    ap p.to_s
        #    ap '---'
        #end
        @@normalize_url_cache[url].dup
    rescue => e
        #ap e
        #ap e.backtrace
        nil
    end

    # @see normalize_url
    def url_sanitize( url )
        normalize_url( url )
    end

    #
    # @param [URI] url
    #
    # @return [String]  domain name
    #
    def extract_domain( url )
        return false if !url.host

        splits = url.host.split( /\./ )

        return splits.first if splits.size == 1

        splits[-2] + "." + splits[-1]
    end

    def path_too_deep?( url )
        opts = Arachni::Options.instance
        path = uri_parse( normalize_url( url ) ).path
        opts.depth_limit > 0 && (opts.depth_limit + 1) <= path.count( '/' )
    end

    #
    # @return   [Bool]  true if uri is in the same domain as the reference URL,
    #                       false otherwise
    #
    def path_in_domain?( uri, ref_url = Arachni::Options.instance.url.to_s )
        return true if !ref_url || ref_url.empty?

        opts = Arachni::Options.instance
        curi = uri_parse( normalize_url( uri.to_s ) )

        if opts.follow_subdomains
            return extract_domain( curi ) == extract_domain( uri_parse( ref_url.to_s ) )
        end

        curi.host == uri_parse( ref_url.to_s ).host
    end

    def exclude_path?( url )
        opts = Arachni::Options.instance
        opts.exclude.each { |pattern| return true if url.to_s =~ pattern }
        false
    end

    def include_path?( url )
        opts = Arachni::Options.instance
        return true if !opts.include || opts.include.empty?

        opts.include.each do |pattern|
            pattern = Regexp.new( pattern ) if pattern.is_a?( String )
            return true if url.to_s =~ pattern
        end
        false
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
    # @param    [String]    reference_url    absolute url to use as a reference
    #
    # @return [String]
    #
    def to_absolute( relative_url, reference_url = Arachni::Options.instance.url.to_s )
        return if !relative_url

        @@to_absolute_cache ||= {}
        key = relative_url + ' :: ' + reference_url
        return @@to_absolute_cache[key].dup if @@to_absolute_cache.include?( key )

        relative  = uri_parse( normalize_url( relative_url ) )
        reference = uri_parse( reference_url )

        @@to_absolute_cache[key] = reference.join( relative ).to_s
        @@to_absolute_cache[key].dup
    rescue
        nil
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

        file = File.open( path + '/' + filename ).each { |line| yield line.strip }
        file.close
    end

    def hash_keys_to_str( hash )
        nh = {}
        hash.each_pair do |k, v|
            nh[k.to_s] = v
            nh[k.to_s] = hash_keys_to_str( v ) if v.is_a? Hash
        end
        nh
    end

    #
    # Wraps the "block" in exception handling code and runs it.
    #
    # @param    [Bool]  raise_exception  re-raise exception
    # @param    [Block]     block   to call
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
