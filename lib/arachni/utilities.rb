=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'securerandom'
require 'digest/sha2'
require 'cgi'

module Arachni

# Includes some useful methods for the system.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Utilities

    # @return   [String]
    #   Filename (without extension) of the caller.
    def caller_name
        File.basename( caller_path( 3 ), '.rb' )
    end

    # @return   [String]
    #   Filepath of the caller.
    def caller_path( offset = 2 )
        ::Kernel.caller[offset].split( /:(\d+):in/ ).first
    end

    # @return   [String]    random HEX (SHA2) string
    def seed
        @@seed ||= generate_token
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

    # @see Arachni::Element::Link.from_response
    def links_from_response( *args )
        Link.from_response( *args )
    end

    # @see Arachni::Element::Link.from_document
    def links_from_document( *args )
        Link.from_document( *args )
    end

    # @see Arachni::Element::Link.parse_query
    def link_parse_query( *args )
        Link.parse_query( *args )
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

    # @see Arachni::Element::Cookie.decode
    def cookie_decode( *args )
        Cookie.decode( *args )
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
    def uri_encode( *args )
        URI.encode( *args )
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
    # @return   [Bool]
    #   `true` is the path exceeds the framework limit, `false` otherwise.
    #
    # @see URI.too_deep?
    # @see OptionGroups::Scope#directory_depth_limit
    #
    def path_too_deep?( url )
        uri_parse( url ).too_deep?( Options.scope.directory_depth_limit )
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
    # @see OptionGroups::Scope#include_subdomains
    #
    def path_in_domain?( url, reference = Options.url )
        uri_parse( url ).in_domain?( !Options.scope.include_subdomains, reference )
    end

    #
    # Decides whether the given `url` matches any framework exclusion rules.
    #
    # @param    [String]    url
    #
    # @return   [Bool]
    #
    # @see URI.exclude?
    # @see OptionGroups::Scope#exclude_path_patterns
    #
    def exclude_path?( url )
        uri_parse( url ).exclude?( Options.scope.exclude_path_patterns )
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
        uri_parse( url ).include?( Options.scope.include_path_patterns )
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
    # @see OptionGroups::Scope#redundant_path_patterns?
    #
    def redundant_path?( url, &block )
        Options.scope.redundant?( url, &block )
    end

    #
    # Decides whether the given `url` has an acceptable protocol.
    #
    # @param    [String]    url
    # @param    [String]    reference   Reference URL.
    #
    # @return   [Bool]
    #
    # @see OptionGroups::Scope#https_only
    # @see OptionGroups::Scope#https_only?
    #
    def follow_protocol?( url, reference = Options.url )
        return true if !reference
        check_scheme = uri_parse( url ).scheme

        return false if !%(http https).include?( check_scheme.to_s.downcase )

        ref_scheme   = uri_parse( reference ).scheme
        return true if ref_scheme && ref_scheme != 'https'
        return true if ref_scheme == check_scheme

        !Options.scope.https_only?
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

    # Determines whether or not the given {Arachni::HTTP::Response} should be
    # ignored.
    #
    # @param    [Arachni::HTTP::Response]   response
    #
    # @return   [Bool]
    #   `true` if the `#body` of the given object matches any of the exclusion
    #   patterns, `false` otherwise.
    #
    # @see #skip_path?
    # @see OptionGroups::Scope#exclude_binaries?
    # @see OptionGroups::Scope#exclude_page?
    def skip_response?( response )
        (Options.audit.exclude_binaries? && !response.text?) ||
            skip_path?( response.url ) ||
            Options.scope.exclude_page?( response.body )
    end

    # Determines whether or not the given {Arachni::Page}.
    #
    # @param    [Page]   page
    #
    # @return   [Bool]
    #   `true` if the `#body` of the given object matches any of the exclusion
    #   patterns or the  {OptionGroups::Scope#dom_depth_limit} has been reached,
    #   `false` otherwise.
    #
    # @see #skip_path?
    # @see OptionGroups::Audit#exclude_binaries?
    # @see OptionGroups::Scope#exclude_page?
    # @see OptionGroups::Scope#dom_depth_limit
    def skip_page?( page )
        skip_response?( page.response ) || Options.scope.dom_depth_limit_reached?( page )
    end

    #
    # Determines whether or not the given `resource` should be ignored
    # depending on its type and content.
    #
    # @param    [Page,Arachni::HTTP::Response,String]    resource
    #   If given a:
    #
    #       * {Page}: both its URL and body will be examined.
    #       * {Arachni::HTTP::Response}: both its effective URL and body will be examined.
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

            when Arachni::HTTP::Response
                skip_response?( resource )

            else
                if (s = resource.to_s) =~ /[\r\n]/
                    Options.scope.exclude_page? s
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
    # @see OptionGroups::Dispatcher#instance_port_range
    def rand_port
        first, last = Options.dispatcher.instance_port_range
        range = (first..last).to_a

        range[ rand( range.last - range.first ) ]
    end

    def generate_token
        SecureRandom.hex
    end

    # Checks whether the port number is available.
    #
    # @param    [Fixnum]  port
    #
    # @return   [Bool]
    def port_available?( port )
        begin
            TCPServer.new( '127.0.0.1', port ).close
            true
        rescue
            false
        end
    end

    # @param    [String, Float, Integer]    seconds
    # @return    [String]
    #   Time in `00:00:00` (`hours:minutes:seconds`) format.
    def secs_to_hms( seconds )
        seconds = seconds.to_i
        [seconds / 3600, seconds / 60 % 60, seconds % 60].
            map { |t| t.to_s.rjust( 2, '0' ) }.join( ':' )
    end

    # Wraps the "block" in exception handling code and runs it.
    #
    # @param    [Bool]  raise_exception  re-raise exception
    # @param    [Block]     block   to call
    def exception_jail( raise_exception = true, &block )
        block.call
    rescue => e
        if respond_to?( :print_error ) && respond_to?( :print_error_backtrace )
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
        end

        raise e if raise_exception

        nil
    end

    def remove_constants( mod, skip = [], children_only = true )
        return if skip.include?( mod )
        return if !(mod.is_a?( Class ) || mod.is_a?( Module )) ||
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
