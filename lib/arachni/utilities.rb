=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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
require 'digest/sha2'
require 'cgi'

module Arachni

#
# Includes some useful methods for the system, the modules etc.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Utilities

    # @return   [String]    random HEX (SHA2) string
    def seed
        @@seed ||= Digest::SHA2.hexdigest( srand( 1000 ).to_s )
    end

    # @see Arachni::Element::Form.from_response
    def forms_from_response( *args )
        Form.from_response( *args )
    end

    # @see Arachni::Element::Form.from_document
    def forms_from_document( *args )
        Form.from_document( *args )
    end

    # @see Arachni::Element::Form.encode
    def form_encode( *args )
        Form.encode( *args )
    end

    # @see Arachni::Element::Form.decode
    def form_decode( *args )
        Form.decode( *args )
    end

    # @see Arachni::Element::Form.parse_request_body
    def form_parse_request_body( *args )
        Form.parse_request_body( *args )
    end
    alias :parse_request_body :form_parse_request_body

    # @see Arachni::Element::Link.from_response
    def links_from_response( *args )
        Link.from_response( *args )
    end

    # @see Arachni::Element::Link.from_document
    def links_from_document( *args )
        Link.from_document( *args )
    end

    # @see Arachni::Element::Link.parse_query_vars
    def parse_url_vars( *args )
        Link.parse_query_vars( *args )
    end
    def parse_query( *args )
        Link.parse_query_vars( *args )
    end

    # @see Arachni::Element::Cookie.from_response
    def cookies_from_response( *args )
        Cookie.from_response( *args )
    end

    # @see Arachni::Element::Cookie.from_document
    def cookies_from_document( *args )
        Cookie.from_document( *args )
    end

    # @see Arachni::Element::Cookie.parse_set_cookie
    def parse_set_cookie( *args )
        Cookie.parse_set_cookie( *args )
    end

    # @see Arachni::Element::Cookie.from_file
    def cookies_from_file( *args )
        Cookie.from_file( *args )
    end

    # @see Arachni::Element::Cookie.encode
    def cookie_encode( *args )
        Cookie.encode( *args )
    end

    # @see Arachni::Page.from_response
    def page_from_response( *args )
        Page.from_response( *args )
    end

    # @see Arachni::Page.from_url
    def page_from_url( *args, &block )
        Page.from_url( *args, &block )
    end

    def html_decode( str )
        ::CGI.unescapeHTML( str.to_s )
    end
    alias :html_unescape :html_decode

    def html_encode( str )
        ::CGI.escapeHTML( str.to_s )
    end
    alias :html_escape :html_encode

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
    def to_absolute( relative_url, reference_url = Options.instance.url.to_s )
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
    # @return  [String]   path
    #   Full URL up to the path component (no resource, query etc.).
    #
    # @see URI.up_to_path
    #
    def get_path( url )
        uri_parse( url ).up_to_path
    end

    #
    # @param    [String] url
    #
    # @return   [String]  Domain name.
    #
    # @see URI.domain
    #
    def extract_domain( url )
        uri_parse( url ).domain
    end

    #
    # @param    [String] url
    #
    # @return   [Bool]
    #   `true` is the path exceeds the framework limit, `false` otherwise.
    #
    # @see URI.too_deep?
    # @see Options#depth_limit
    #
    def path_too_deep?( url )
        uri_parse( url ).too_deep?( Options.depth_limit )
    end

    #
    # Compares 2 urls in order to decide whether or not they belong to the same domain.
    #
    # @param    [String]    url
    # @param    [String]    reference
    #
    # @return   [Bool]
    #   `true` if self is in the same domain as the `reference` URL, false otherwise.
    #
    # @see URI.in_domain?
    # @see Options#follow_subdomains
    #
    def path_in_domain?( url, reference = Options.url )
        uri_parse( url ).in_domain?( !Options.follow_subdomains, reference )
    end

    #
    # Decides whether the given `url` matches any framework exclusion rules.
    #
    # @param    [String]    url
    #
    # @return   [Bool]
    #
    # @see URI.exclude?
    # @see Options#exclude
    #
    def exclude_path?( url )
        uri_parse( url ).exclude?( Options.exclude )
    end

    #
    # Decides whether the given `url` matches any framework inclusion rules.
    #
    # @param    [String]    url
    #
    # @return   [Bool]
    #
    # @see URI.include?
    # @see Options#include
    #
    def include_path?( url )
        uri_parse( url ).include?( Options.include )
    end

    #
    # Checks if the provided URL matches a redundant filter
    # and decreases its counter if so.
    #
    # If a filter's counter has reached 0 the method returns true.
    #
    # @param    [String]  url
    #
    # @return   [Bool]    `true` if the `url` is redundant, `false` otherwise.
    #
    # @see Options#redundant?
    #
    def redundant_path?( url, &block )
        Options.redundant?( url, &block )
    end

    #
    # Decides whether the given `url` has an acceptable protocol.
    #
    # @param    [String]    url
    # @param    [String]    reference   Reference URL.
    #
    # @return   [Bool]
    #
    # @see Options#https_only
    # @see Options#https_only?
    #
    def follow_protocol?( url, reference = Options.url )
        return true if !reference
        check_scheme = uri_parse( url ).scheme

        return false if !%(http https).include?( check_scheme.to_s.downcase )

        ref_scheme   = uri_parse( reference ).scheme
        return true if ref_scheme && ref_scheme != 'https'
        return true if ref_scheme == check_scheme

        !Options.https_only?
    end

    #
    # Decides whether or not the provided `path` should be skipped based on:
    #
    # * {#include_path?}
    # * {#exclude_path?}
    # * {#path_too_deep?}
    # * {#path_in_domain?}
    #
    # @note Does **not** call {#redundant_path?}.
    #
    # @param    [Arachni::URI, ::URI, Hash, String] path
    #
    # @return   [Bool]
    #
    def skip_path?( path )
        return true if !path

        parsed = uri_parse( path.to_s )

        begin
            return true if !follow_protocol?( parsed )
            return true if !path_in_domain?( parsed )
            return true if path_too_deep?( parsed )
            return true if !include_path?( parsed )
            return true if exclude_path?( parsed )
            false
        rescue => e
            ap e
            ap e.backtrace
            true
        end
    end

    #
    # Determines whether or not a given {Arachni::Page} or {Typhoeus::Response}
    # should be ignored.
    #
    # @param    [Page,Typhoeus::Response,#body]   page_or_response
    #
    # @return   [Bool]
    #   `true` if the `#body` of the given object matches any of the exclusion
    #   patterns, `false` otherwise.
    #
    # @see #skip_path?
    # @see Options#exclude_binaries?
    # @see Options#exclude_page?
    #
    def skip_page?( page_or_response )
        (Options.exclude_binaries? && !page_or_response.text?) ||
            skip_path?( page_or_response.url ) ||
            Options.exclude_page?( page_or_response.body )
    end
    alias :skip_response? :skip_page?

    #
    # Determines whether or not the given `resource` should be ignored
    # depending on its type and content.
    #
    # @param    [Page,Typhoeus::Response,String]    resource
    #   If given a:
    #
    #       * {Page}: both its URL and body will be examined.
    #       * {Typhoeus::Response}: both its effective URL and body will be examined.
    #       * {String}: if multi-line it will be treated as a response body,
    #           otherwise as a path.
    #
    # @return   [Bool]
    #   `true` if the resource should be ignore,`false` otherwise.
    #
    # @see skip_path?
    # @see ignore_page?
    # @see ignore_response?
    # @see Options#ignore?
    #
    def skip_resource?( resource )
        case resource
            when Page
                skip_page?( resource )

            when Typhoeus::Response
                skip_response?( resource )

            else
                if (s = resource.to_s) =~ /[\r\n]/
                    Options.exclude_page? s
                else
                    skip_path? s
                end
        end
    end

    # @return   [Fixnum]  Random available port number.
    def available_port
        nil while !port_available?( port = rand_port )
        port
    end

    # @return   [Integer]   Random port within the user specified range.
    # @see Options#rpc_instance_port_range
    def rand_port
        first, last = Options.rpc_instance_port_range
        range = (first..last).to_a

        range[ rand( range.last - range.first ) ]
    end

    def generate_token
        secret = ''
        1000.times { secret << rand( 9999 ).to_s }
        Digest::SHA2.hexdigest( secret )
    end

    #
    # Checks whether the port number is available.
    #
    # @param    [Fixnum]  port
    #
    # @return   [Bool]
    #
    def port_available?( port )
        begin
            socket = Socket.new( :INET, :STREAM, 0 )
            socket.bind( Addrinfo.tcp( '127.0.0.1', port ) )
            socket.close
            true
        rescue
            false
        end
    end

    #
    # Wraps the "block" in exception handling code and runs it.
    #
    # @param    [Bool]  raise_exception  re-raise exception
    # @param    [Block]     block   to call
    #
    def exception_jail( raise_exception = true, &block )
        block.call
    rescue Exception => e
        begin
            print_error e.inspect
            print_error_backtrace e
            print_error
            print_error 'Parent:'
            print_error  self.class.to_s
            print_error
            print_error 'Block:'
            print_error block.to_s
            print_error
            print_error 'Caller:'
            ::Kernel.caller.each { |l| print_error l }
            print_error '-' * 80
        rescue
        end
        raise e if raise_exception
    end

    def remove_constants( mod, skip = [], children_only = true )
        return if skip.include?( mod )
        return if !(mod.is_a?( Class ) || !mod.is_a?( Module )) ||
            !mod.to_s.start_with?( 'Arachni' )

        parent = Object
        mod.to_s.split( '::' )[0..-2].each do |ancestor|
            parent = parent.const_get( ancestor.to_sym )
        end

        mod.constants.each { |m| mod.send( :remove_const, m ) }

        return if children_only
        parent.send( :remove_const, mod.to_s.split( ':' ).last.to_sym )
    end

    extend self

end

end
