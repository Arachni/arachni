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

#
# Includes some useful methods for the system, the modules etc...
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Utilities

    # @return   [String]    random HEX (SHA2) string
    def seed
        @@seed ||= Digest::SHA2.hexdigest( srand( 1000 ).to_s )
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

    # @return [URI::Parser] cached URI parser
    def uri_parser
        URI.parser
    end

    # @see URI.parse
    def uri_parse( url )
        URI.parse( url )
    end

    # @see URI.encode
    def uri_encode( string, bad_characters = nil )
        URI.encode( string, bad_characters )
    end

    # @see URI.encode
    def uri_decode( url )
        URI.decode( url )
    end

    # @see URI.to_absolute
    def to_absolute( relative_url, reference_url = Arachni::Options.instance.url.to_s )
        URI.to_absolute( relative_url, reference_url )
    end

    # @see URI.normalize
    def normalize_url( url )
        URI.normalize( url )
    end

    # @see normalize_url
    def url_sanitize( url )
        normalize_url( url )
    end

    #
    # @param   [String]   url
    #
    # @return  [String]   path  full URL up to the path component (no resource, query etc.)
    #
    # @see URI.up_to_path
    #
    def get_path( url )
        uri_parse( url ).up_to_path
    end

    #
    # @param    [String] url
    #
    # @return   [String]  domain name
    #
    # @see URI.domain
    #
    def extract_domain( url )
        uri_parse( url ).domain
    end

    #
    # @param    [String] url
    #
    # @return   [Bool]  +true+ is the path exceeds the framework limit, +false+ otherwise
    #
    # @see URI.too_deep?
    #
    def path_too_deep?( url )
        uri_parse( url ).too_deep?( Arachni::Options.instance.depth_limit )
    end

    #
    # Compares 2 urls in order to decide whether or not they belong to the same domain.
    #
    # @param    [String]    url
    # @param    [String]    reference
    #
    # @return   [Bool]  +true+ if self is in the same domain as the +reference+ URL,
    #                       false otherwise
    #
    # @see URI.in_domain?
    #
    def path_in_domain?( url, reference = Arachni::Options.instance.url )
        uri_parse( url ).in_domain?( !Arachni::Options.instance.follow_subdomains, reference )
    end

    #
    # Decides whether the given +url+ matches any framework exclusion rules.
    #
    # @param    [String]    url
    #
    # @return   [Bool]
    #
    def exclude_path?( url )
        #opts = Arachni::Options.instance
        #opts.exclude.each { |pattern| return true if url.to_s =~ pattern }
        #false
        uri_parse( url ).exclude?( Arachni::Options.instance.exclude )
    end

    #
    # Decides whether the given +url+ matches any framework inclusion rules.
    #
    # @param    [String]    url
    #
    # @return   [Bool]
    #
    def include_path?( url )
        #opts = Arachni::Options.instance
        #return true if !opts.include || opts.include.empty?
        #
        #opts.include.each do |pattern|
        #    pattern = Regexp.new( pattern ) if pattern.is_a?( String )
        #    return true if url.to_s =~ pattern
        #end
        #false
        uri_parse( url ).include?( Arachni::Options.instance.include )
    end

    #
    # Decides whether or not the provided +path+ should be skipped based on:
    # * {#include_path?}
    # * {#exclude_path?}
    # * {#path_too_deep?}
    # * {#path_in_domain?}
    #
    # @param
    #
    # @return   [Bool]
    #
    def skip_path?( path )
        return true if !path

        parsed = uri_parse( path )
        begin
            return true if !include_path?( parsed )
            return true if exclude_path?( parsed )
            return true if path_too_deep?( parsed )
            return true if !path_in_domain?( parsed )
            false
        rescue
            true
        end
    end

    #
    # Recursively converts a Hash's keys to strings
    #
    # @param    [Hash]  hash
    #
    # @return   [Hash]
    #
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
