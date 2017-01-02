=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

module Platform

# Namespace under which all platform fingerprinter components reside.
module Fingerprinters
end

# Provides utility methods for fingerprinter components as well as
# the {Page} object to be fingerprinted
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @abstract
class Fingerprinter
    include Utilities

    # @return   [Page]
    #   Page to fingerprint.
    attr_reader :page

    def initialize( page )
        @page = page
    end

    # Executes the payload of the fingerprinter.
    #
    # @abstract
    def run
    end

    def html?
        @is_html ||= page.response.headers['content-type'].to_s.
            downcase.include?( 'text/html' )
    end

    # @param    [String]    string
    #
    # @return   [Boolean]
    #   `true` if either {#server} or {#powered_by} include `string`,
    #   `false` otherwise.
    def server_or_powered_by_include?( string )
        server.include?( string.downcase ) || powered_by.include?( string.downcase )
    end

    # @return   [Arachni::URI]
    #   Parsed URL of the {#page}.
    def uri
        uri_parse( page.url )
    end

    # @return   [Hash]
    #   URI parameters with keys and values downcased.
    def parameters
        @parameters ||= page.query_vars.downcase
    end

    # @return   [Hash]
    #   Cookies as headers with keys and values downcased.
    def cookies
        @cookies ||= page.cookies.
            inject({}) { |h, c| h.merge! c.simple }.downcase
    end

    # @return   [Hash]
    #   Response headers with keys and values downcased.
    def headers
        @headers ||= page.response.headers.downcase
    end

    # @return   [String. nil]
    #   Downcased value of the `X-Powered-By` header.
    def powered_by
        headers['x-powered-by'].to_s.downcase
    end

    # @return   [String. nil]
    #   Downcased value of the `Server` header.
    def server
        headers['server'].to_s.downcase
    end

    # @return   [String]
    #   Downcased file extension of the page.
    def extension
        @extension ||= uri_parse( page.url ).resource_extension.to_s.downcase
    end

    # @return   [Platform]
    #   Platform for the given page, should be updated by the
    #   fingerprinter accordingly.
    def platforms
        page.platforms
    end

end

end
end
