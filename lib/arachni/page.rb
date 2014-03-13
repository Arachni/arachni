=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

# It holds page data like elements, cookies, headers, etc...
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Page
    include Utilities

    class Error < Arachni::Error
    end

    require_relative 'page/dom'

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

        data[:response][:request]       ||= {}
        data[:response][:request][:url] ||= data[:response][:url]

        data[:links]   ||= []
        data[:forms]   ||= []
        data[:cookies] ||= []
        data[:headers] ||= []

        data[:cookiejar] ||= []

        data[:response][:request] = Arachni::HTTP::Request.new( data[:response][:request] )
        data[:response]           = Arachni::HTTP::Response.new( data[:response] )

        new data
    end

    # @return   [DOM]   DOM snapshot.
    attr_reader :dom

    # @return   [Set<Integer>]
    #   Audit whitelist based on {Element::Capabilities::Auditable#audit_scope_id}.
    #
    # @see  #update_element_audit_whitelist
    # @see  #audit_element?
    # @see  Check::Auditor#skip?
    attr_reader :element_audit_whitelist

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
        options = options.dup

        if response = options.delete(:response)
            @parser = Parser.new( response )
        end

        @parser ||= options.delete(:parser)

        options.each do |k, v|
            dupped = try_dup( v )
            begin
                send( "#{k}=", dupped )
            rescue NoMethodError
                instance_variable_set( "@#{k}".to_sym, dupped )
            end
        end

        @dom = DOM.new( (options[:dom] || {}).merge( page: self ) )

        fail ArgumentError, 'No URL given!' if !url

        Platform::Manager.fingerprint( self )

        @element_audit_whitelist ||= []
        @element_audit_whitelist   = Set.new( @element_audit_whitelist )
    end

    def performer
        request.performer
    end

    # @param    [Array<Element::Capabilities::Auditable, Integer>]    list
    #   Audit whitelist based on {Element::Capabilities::Auditable elements} or
    #   {Element::Capabilities::Auditable#audit_scope_id}s.
    # @return   [Set]   {#element_audit_whitelist}
    #
    # @see  #element_audit_whitelist
    # @see  Check::Auditor#skip?
    def update_element_audit_whitelist( list )
        [list].flatten.each do |e|
            @element_audit_whitelist << (e.is_a?( Integer ) ? e : e.audit_scope_id )
        end
    end

    # @param    [Element::Capabilities::Auditable, Integer]    element
    #   Element or {Element::Capabilities::Auditable#audit_scope_id}.
    # @return   [Bool]
    #   `true` if the element should be audited, `false` otherwise.
    #
    # @see  #element_audit_whitelist
    # @see  Check::Auditor#skip?
    def audit_element?( element )
        return if @do_not_audit_elements
        return true if @element_audit_whitelist.empty?
        @element_audit_whitelist.include?(
            element.is_a?( Integer ) ? element : element.audit_scope_id
        )
    end

    # It forces {#audit_element?} to always returns false.
    def do_not_audit_elements
        @do_not_audit_elements = true
    end

    # @return    [HTTP::Response]    HTTP response.
    def response
        return if !@parser
        @parser.response
    end

    # @return    [HTTP::Request]    HTTP request.
    def request
        response.request
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
        @links = @forms = @cookies = @document = @has_javascript = nil
        @parser.body = @body = string.dup.freeze
    end

    # @return    [Array<Element::Link>]
    # @see Parser#links
    def links
        @links ||=
            assign_page_to_elements( (!@links && !@parser) ? [] : @parser.links )
    end

    # @param    [Array<Element::Link>]  links
    # @see Parser#links
    def links=( links )
        @links = assign_page_to_elements( links )
    end

    # @return    [Array<Element::Form>]
    # @see Parser#forms
    def forms
        @forms ||=
            assign_page_to_elements( (!@forms && !@parser) ? [] : @parser.forms )
    end

    # @param    [Array<Element::Form>]  forms
    # @see Parser#forms
    def forms=( forms )
        @forms = assign_page_to_elements( forms )
    end

    # @return    [Array<Element::Cookie>]
    # @see Parser#cookies
    def cookies
        @cookies ||=
            assign_page_to_elements(
                (!@cookies && !@parser) ? [] : @parser.cookies_to_be_audited
            )
    end

    # @param    [Array<Element::Cookies>]  cookies
    # @see Parser#cookies
    def cookies=( cookies )
        @cookies = assign_page_to_elements( cookies )
    end

    # @return    [Array<Element::Header>]   HTTP request headers.
    def headers
        @headers ||=
            assign_page_to_elements( (!@headers && !@parser) ? [] : @parser.headers )
    end

    # @param    [Array<Element::Headers>]  headers
    # @see Parser#headers
    def headers=( headers )
        @headers = assign_page_to_elements( headers )
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

    def clear_caches
        [@forms, @links, @cookies, @headers].flatten.compact.each { |e| e.page = nil }
        @query_vars = @paths = @document = @forms = @links = @cookies = @headers = nil
        nil
    end

    # @return   [Boolean]
    #   `true` if the page contains client-side code, `false` otherwise.
    def has_script?
        return if !document || !text? ||
            !response.headers.content_type.to_s.start_with?( 'text/html' )

        return @has_javascript if !@has_javascript.nil?

        # First check, quick and simple.
        return @has_javascript = true if document.css( 'script' ).any?

        # Check for event attributes, if there are any then there's JS to be
        # executed.
        Browser.events.flatten.each do |event|
            return @has_javascript = true if document.xpath( "//*[@#{event}]" ).any?
        end

        # If there's 'javascript:' in 'href' and 'action' attributes then
        # there's JS to be executed.
        [:action, :href].each do |candidate|
            document.xpath( "//*[@#{candidate}]" ).each do |attribute|
                if attribute.attributes[candidate.to_s].to_s.start_with?( 'javascript:' )
                    return @has_javascript = true
                end
            end
        end

        @has_javascript = false
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
        "#{dom.playable_transitions.hash}:#{body.hash}:#{elements.map(&:hash).sort}".hash
    end

    def ==( other )
        hash == other.hash
    end

    def eql?( other )
        self == other
    end

    def dup
        # TODO: Maybe self.class.new( _dump() )
        self.deep_clone
    end

    # TODO: Maybe move most of the code to #to_h.
    def _dump( _ )
        h = {}
        [:body, :links, :forms, :cookies, :headers, :cookiejar, :paths,
         :element_audit_whitelist].each do |m|
            h[m] = instance_variable_get( "@#{m}".to_sym )
            h.delete( m ) if !h[m]
        end

        h[:response] = response

        [:links, :forms, :cookies, :headers] .each do |m|
            #h.delete m
            next if !h[m]
            h[m] = h[m].map(&:dup).each { |e| e.page = nil }
        end

        h[:dom] = dom.to_h

        Marshal.dump( h )
    end

    def self._load( data )
        new( Marshal.load( data ) )
    end

    private

    def assign_page_to_elements( list )
        list.map { |e| e.page = self; e }.freeze
    end

    def try_dup( v )
        v.dup rescue v
    end

end
end
