=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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

module Arachni

module Platform

# Namespace under which all platform fingerprinter components reside.
module Fingerprinters
end

#
# Provides utility methods for fingerprinter components as well as
# the {Page} object to be fingerprinted
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Fingerprinter
    include Utilities

    # @return   [Page]  Page to fingerprint.
    attr_reader :page

    def initialize( page )
        @page = page
    end

    # Executes the payload of the fingerprinter.
    # @abstract
    def run
    end

    # @param    [String]    string
    # @return   [Boolean]
    #   `true` if either {#server} or {#powered_by} include `string`,
    #   `false` otherwise.
    def server_or_powered_by_include?( string )
        server.include?( string.downcase ) || powered_by.include?( string.downcase )
    end

    # @return   [Arachni::URI]  Parsed URL of the {#page}.
    def uri
        uri_parse( page.url )
    end

    # @return   [Hash]  URI parameters with keys and values downcased.
    def parameters
        @parameters ||= page.query_vars.downcase
    end

    # @return   [Hash]  Cookies as headers with keys and values downcased.
    def cookies
        @cookies ||= page.cookies.
            inject({}) { |h, c| h.merge! c.simple }.downcase
    end

    # @return   [Hash]  Response headers with keys and values downcased.
    def headers
        @headers ||= page.response_headers.downcase
    end

    # @return   [String. nil] Downcased value of the `X-Powered-By` header.
    def powered_by
        headers['x-powered-by'].to_s.downcase
    end

    # @return   [String. nil] Downcased value of the `Server` header.
    def server
        headers['server'].to_s.downcase
    end

    # @return   [String] Downcased file extension of the page.
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
