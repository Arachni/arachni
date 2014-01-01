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

#
# It holds page data like elements, cookies, headers, etc...
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Page

    # @return    [String]    URL of the page
    attr_reader :url

    # @return    [Fixnum]    HTTP response code.
    attr_reader :code

    # @return    [Hash]    URL query parameters.
    attr_reader :query_vars

    # @return    [String]    HTTP response body.
    attr_reader :body

    # @return    [Array<Element::Header>]   HTTP request headers.
    attr_reader :headers

    # @return    [Hash] HTTP request headers.
    attr_reader :request_headers

    # @return    [Hash] HTTP response headers.
    attr_reader :response_headers

    # @return    [Array<String>]    Paths contained in this page.
    attr_reader :paths

    # @see Parser#links
    # @return    [Array<Element::Link>]
    attr_accessor :links

    # @see Parser#forms
    # @return    [Array<Element::Form>]
    attr_accessor :forms

    # @see Parser#cookies
    # @return    [Array<Element::Cookie>]
    attr_accessor :cookies

    # @return    [Array<Element::Cookie>]
    #   Cookies extracted from the supplied cookie-jar.
    attr_accessor :cookiejar

    # @param    [String]    url URL to fetch.
    # @param    [Hash]  opts
    # @option  opts    [Integer]   :precision  (1)
    #   How many times to request the page and examine changes between requests.
    #   Used tp identify nonce tokens etc.
    # @option  opts    [Hash]  :http   HTTP {HTTP#get request} options.
    # @param    [Block] block
    #   Block to which to pass the page object. If given, the request will be
    #   performed asynchronously. If no block is given, the page will be fetched
    #   synchronously and be returned by this method.
    # @return   [Page]
    def self.from_url( url, opts = {}, &block )
        responses = []

        opts[:precision] ||= 1
        opts[:precision].times {
            HTTP.get( url, opts[:http] || {} ) do |res|
                responses << res
                next if responses.size != opts[:precision]
                block.call( from_response( responses ) ) if block_given?
            end
        }

        if !block_given?
            HTTP.run
            from_response( responses )
        end
    end

    # @param    [Typhoeus::Response]    res HTTP response to parse.
    # @return   [Page]
    def self.from_response( res, opts = Options )
        Parser.new( res, opts ).page
    end
    class << self; alias :from_http_response :from_response end

    # @param    [Hash]  opts    Hash from which to set instance attributes.
    def initialize( opts = {} )
        opts.each { |k, v| instance_variable_set( "@#{k}".to_sym, try_dup( v ) ) }

        @forms ||= []
        @links ||= []
        @cookies ||= []
        @headers ||= []

        @cookiejar ||= {}
        @paths ||= []

        @response_headers ||= {}
        @request_headers  ||= {}
        @query_vars       ||= {}

        @url    = Utilities.normalize_url( @url )
        @body ||= ''
    end

    # @return   [Platform] Applicable platforms for the page.
    def platforms
        Platform::Manager[@url]
    end

    # @return   [Array] All page elements.
    def elements
        @links | @forms | @cookies | @headers
    end

    # @return    [String]    the request method that returned the page
    def method( *args )
        return super( *args ) if args.any?
        @method
    end

    # @see #body
    def html
        @body
    end

    # @return   [Nokogiri::HTML]    Parsed {#body HTML} document.
    def document
        @document ||= Nokogiri::HTML( @body )
    end

    def marshal_dump
        instance_variables.inject( {} ) do |h, iv|
            next h if iv == :@document
            h[iv] = instance_variable_get( iv )
            h
        end
    end

    def marshal_load( h )
        h.each { |k, v| instance_variable_set( k, v ) }
    end

    # @return   [Boolean]
    #   `true` if the body of the page is text-base, `false` otherwise.
    def text?
        !!@text
    end

    # @return   [String]    Title of the page.
    def title
        document.css( 'title' ).first.text rescue nil
    end

    # @return   [Hash]  Converts the page data to a hash.
    def to_h
        instance_variables.reduce({}) do |h, iv|
            next h if iv == :@document
            h[iv.to_s.gsub( '@', '').to_sym] = try_dup( instance_variable_get( iv ) )
            h
        end
    end
    alias :to_hash :to_h

    def hash
        ((links.map { |e| e.hash } + forms.map { |e| e.hash } +
            cookies.map { |e| e.hash } + headers.map { |e| e.hash }).sort.join +
            body.to_s).hash
    end

    def ==( other )
        hash == other.hash
    end

    def eql?( other )
        self == other
    end

    def dup
        self.deep_clone
    end

    private

    def try_dup( v )
        v.dup rescue v
    end

end
end
