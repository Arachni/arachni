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

require_relative 'page/dom'

module Arachni

#
# It holds page data like elements, cookies, headers, etc...
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Page

    # @param    [String]    url URL to fetch.
    # @param    [Hash]  opts
    # @option  opts    [Integer]   :precision  (1)
    #   How many times to request the page and examine changes between requests.
    #   Used tp identify nonce tokens etc.
    # @option  opts    [Hash]  :http   HTTP {HTTP::Client#get request} options.
    # @param    [Block] block
    #   Block to which to pass the page object. If given, the request will be
    #   performed asynchronously. If no block is given, the page will be fetched
    #   synchronously and be returned by this method.
    # @return   [Page]
    def self.from_url( url, opts = {}, &block )
        responses = []

        opts[:precision] ||= 1
        opts[:precision].times {
            HTTP::Client.get( url, opts[:http] || {} ) do |res|
                responses << res
                next if responses.size != opts[:precision]
                block.call( from_response( responses ) ) if block_given?
            end
        }

        if !block_given?
            HTTP::Client.run
            from_response( responses )
        end
    end

    # @param    [HTTP::Response]    response    HTTP response to parse.
    # @return   [Page]
    def self.from_response( response )
        new response: response
    end

    # @option options  [String]    :url
    #   URL of the page.
    # @option options  [String]    :body
    #   Body of the page.
    # @option options  [Array<Link>]    :links
    #   {Link} elements.
    # @option options  [Array<Form>]    :forms
    #   {Form} elements.
    # @option options  [Array<Cookie>]    :cookies
    #   {Cookie} elements.
    # @option options  [Array<Header>]    :headers
    #   {Header} elements.
    # @option options  [Array<Cookie>]    :cookiejar
    #   {Cookie} elements with which to update the HTTP cookiejar before
    #   auditing.
    # @option options  [Array<String>]    :paths
    #   Paths contained in the page.
    # @option options  [Array<String>]    :request
    #   {Request#initialize} options.
    def self.from_data( data )
        data = data.dup

        data[:response]        ||= {}
        data[:response][:code] ||= 200
        data[:response][:url]  ||= data.delete( :url )
        data[:response][:body] ||= data.delete( :body ) || ''

        data[:response][:request] ||= {}

        data[:links]   ||= []
        data[:forms]   ||= []
        data[:cookies] ||= []
        data[:headers] ||= []

        data[:cookiejar] ||= []

        data[:response][:request] =
            Arachni::HTTP::Request.new( data[:response][:url], data[:response][:request] )

        data[:response] = Arachni::HTTP::Response.new( data[:response] )

        new data
    end

    attr_reader :dom

    # Needs either a `:parser` or a `:response` or user provided data.
    #
    # @param    [Hash]  options    Hash from which to set instance attributes.
    # @option options  [Array<HTTP::Response>, HTTP::Response]    :response
    #   HTTP response of the page -- or array of responses for the page for
    #   content refinement.
    # @option options  [Parser]    :parser
    #   An instantiated {Parser}.
    def initialize( options )
        fail ArgumentError, 'Options cannot be empty.' if options.empty?

        options.each { |k, v| instance_variable_set( "@#{k}".to_sym, try_dup( v ) ) }

        @parser ||= Parser.new( @response ) if @response
        @dom      = DOM.new( (options[:dom] || {}).merge( page: self ) )

        Platform::Manager.fingerprint( self ) if Options.fingerprint?
    end

    # @return    [HTTP::Response]    HTTP response.
    def response
        return if !@parser
        @parser.response
    end

    # @return    [String]    URL of the page.
    def url
        @url ||= @parser.url
    end

    # @return    [String]    URL of the page.
    def code
        return 0 if !@code && !response
        @code ||= response.code
    end

    # @return    [Hash]    {#url URL} query parameters.
    def query_vars
        @query_vars ||= Link.parse_query_vars( url )
    end

    # @return    [String]    HTTP response body.
    def body
        return '' if !@body && !@parser
        @body ||= response.body
    end

    # @param    [String]    string  Page body.
    def body=( string )
        @links = @forms = @cookies = @document = nil
        dom.clear_caches
        @parser.body = @body = string.dup
    end

    # @return    [Array<Element::Link>]
    # @see Parser#links
    def links
        @links ||= (!@links && !@parser) ? [] : @parser.links
    end

    # @param    [Array<Element::Link>]  links
    # @see Parser#links
    def links=( links )
        @links = links.freeze
    end

    # @return    [Array<Element::Form>]
    # @see Parser#forms
    def forms
        @forms ||= (!@forms && !@parser) ? [] : @parser.forms
    end

    # @param    [Array<Element::Form>]  forms
    # @see Parser#forms
    def forms=( forms )
        @forms = forms.freeze
    end

    # @return    [Array<Element::Cookie>]
    # @see Parser#cookies
    def cookies
        @cookies ||= (!@cookies && !@parser) ? [] : @parser.cookies_to_be_audited
    end

    # @param    [Array<Element::Cookies>]  cookies
    # @see Parser#cookies
    def cookies=( cookies )
        @cookies = cookies.freeze
    end

    # @return    [Array<Element::Header>]   HTTP request headers.
    def headers
        @headers ||= (!@headers && !@parser) ? [] : @parser.headers
    end

    # @param    [Array<Element::Headers>]  headers
    # @see Parser#headers
    def headers=( headers )
        @headers = headers.freeze
    end

    # @return    [Array<Element::Cookie>]
    #   Cookies extracted from the supplied cookie-jar.
    def cookiejar
        @cookiejar ||= (!@cookiejar && !@parser) ? [] : @parser.cookie_jar
    end

    # @return    [Array<String>]    Paths contained in this page.
    # @see Parser#paths
    def paths
        @paths ||= (!@paths && !@parser) ? [] : @parser.paths
    end

    # @return   [Platform] Applicable platforms for the page.
    def platforms
        Platform::Manager[url]
    end

    # @return   [Array] All page elements.
    def elements
        links | forms | cookies | headers
    end

    # @return    [String]    the request method that returned the page
    def method( *args )
        return super( *args ) if args.any?
        response.request.method
    end

    # @return   [Nokogiri::HTML]    Parsed {#body HTML} document.
    def document
        @document ||= (@parser.nil? ? Nokogiri::HTML( body ) : @parser.document)
    end

    # @return   [Boolean]
    #   `true` if the page contains JavaScript code, `false` otherwise.
    def has_javascript?
        document.css( 'script' ).any? if document
    end

    # @return   [Boolean]
    #   `true` if the body of the page is text-base, `false` otherwise.
    def text?
        return false if !@parser
        @parser.text?
    end

    # @return   [String]    Title of the page.
    def title
        document.css( 'title' ).first.text rescue nil
    end

    def hash
        "#{dom.transitions}:#{@body.hash}:#{elements.map(&:hash).sort}".hash
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

    def _dump( _ )
        h = {}
        [:response, :body, :links, :forms, :cookies, :headers, :cookiejar,
         :paths].each do |m|
            h[m] = send( m )
        end

        h[:forms].each { |f| f.node = nil }

        h[:dom_transitions] = dom.transitions

        Marshal.dump( h )
    end

    def self._load( data )
        options = Marshal.load( data )
        transitions = options.delete( :dom_transitions )

        page = new( options )
        page.dom.transitions = transitions
        page
    end

    private

    def try_dup( v )
        v.dup rescue v
    end

end
end
