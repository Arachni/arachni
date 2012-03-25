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

module Arachni

class Parser
#
# Arachni::Page class
#
# It holds page data like elements, cookies, headers, etc...
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
#
class Page

    #
    # @return    [String]    url of the page
    #
    attr_accessor :url

    #
    # @return    [Fixnum]    the HTTP response code
    #
    attr_accessor :code

    #
    # @return    [String]    the request method that returned the page
    #
    attr_accessor :method

    #
    # @return    [Hash]    url variables
    #
    attr_accessor :query_vars

    #
    # @return    [String]    the HTML response
    #
    attr_accessor :html

    #
    # Request headers
    #
    # @return    [Array<Arachni::Parser::Element::Header>]
    #
    attr_accessor :headers

    #
    # @return    [Hash]
    #
    attr_accessor :response_headers

    attr_accessor :paths

    #
    # @see Parser#links
    #
    # @return    [Array<Arachni::Parser::Element::Link>]
    #
    attr_accessor :links

    #
    # @see Parser#forms
    #
    # @return    [Array<Arachni::Parser::Element::Form>]
    #
    attr_accessor :forms

    #
    # @see Parser#cookies
    #
    # @return    [Array<Arachni::Parser::Element::Cookie>]
    #
    attr_accessor :cookies

    #
    # Cookies extracted from the supplied cookiejar
    #
    # @return    [Hash]
    #
    attr_accessor :cookiejar

    def self.from_http_response( res, opts )
        page = Arachni::Parser.new( opts, res ).run
        page.url = Arachni::Module::Utilities.url_sanitize( res.effective_url )
        return page
    end

    def initialize( opts = {} )

        @forms = []
        @links = []
        @cookies = []
        @headers = []

        @cookiejar = {}
        @paths = []

        @response_headers = {}
        @query_vars       = {}

        opts.each {
            |k, v|
            send( "#{k}=", v )
        }

        @html ||= ''
    end

    def body
        @html
    end

    def body=( str )
        @html = str
    end

end
end
end
