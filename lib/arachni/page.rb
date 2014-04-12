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
    # @option  opts    [Integer]   :precision  (2)
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

        opts[:precision] ||= 2
        opts[:precision].times do
            HTTP::Client.get( url, opts[:http] || {} ) do |res|
                responses << res
                next if responses.size != opts[:precision]
                block.call( from_response( responses ) ) if block_given?
            end
        end

        if !block_given?
            HTTP::Client.run
            from_response( responses )
        end
    end

    # @param    [HTTP::Response]    response    HTTP response to parse.
    # @return   [Page]
    def self.from_response( response )
        Parser.new( response ).page
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
    attr_accessor :dom

    # @return    [HTTP::Response]    HTTP response.
    attr_reader :response

    # @return    [Hash]
    # @private
    attr_reader :cache

    # @return    [Hash]
    #   Holds page data that will need to persist between {#clear_cache} calls
    #   and other utility data.
    attr_reader :metadata

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

        @cache = {}

        @cache[:parser] = options.delete(:parser)
        @response = @cache[:parser].response if @cache[:parser]

        # We need to know whether or not the page has been dynamically updated
        # with elements, in order to optimize #dup and #hash operations.
        @has_custom_elements = Set.new

        @metadata ||= {}

        options.each do |k, v|
            send( "#{k}=", try_dup( v ) )
        end

        @dom = DOM.new( (options[:dom] || {}).merge( page: self ) )

        fail ArgumentError, 'No URL given!' if !url

        Platform::Manager.fingerprint( self )

        @element_audit_whitelist ||= []
        @element_audit_whitelist   = Set.new( @element_audit_whitelist )
    end

    # @return   [Object]
    #   Object which performed the {#request} which lead to this page.
    def performer
        request.performer
    end

    # @return   [Parser]
    def parser
        return if !@response
        return @cache[:parser] if @cache[:parser]

        @cache[:parser] = Parser.new( @response )

        # The page may have a browser-assigned body, set it as the one to parse.
        @cache[:parser].body = body
        @cache[:parser]
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

    # @return    [HTTP::Request]    HTTP request.
    def request
        response.request
    end

    # @return    [String]    URL of the page.
    def url
        @url ||= @response.url
    end

    # @return    [String]    URL of the page.
    def code
        return 0 if !@code && !response
        @code ||= response.code
    end

    # @return    [Hash]    {#url URL} query parameters.
    def query_vars
        @cache[:query_vars] ||= Link.parse_query_vars( url )
    end

    # @return    [String]    HTTP response body.
    def body
        return '' if !@body && !@response
        @body ||= response.body
    end

    # @param    [String]    string  Page body.
    def body=( string )
        @has_javascript = nil
        clear_cache

        @body = string.to_s.dup.freeze
    end

    [:links, :forms, :cookies, :headers].each do |type|
        parser_method = type
        parser_method = :cookies_to_be_audited if type == :cookies

        define_method type do
            @cache[type] ||=
                assign_page_to_elements( parser ? parser.send(parser_method) : [] )
        end

        define_method "#{type}=" do |elements|
            @has_custom_elements << type
            @cache[type] = assign_page_to_elements( elements )
        end
    end

    # @return    [Array<Element::Cookie>]
    #   Cookies extracted from the supplied cookie-jar.
    def cookiejar
        @cookiejar ||= (parser ? parser.cookie_jar : [])
    end

    # @return    [Array<String>]    Paths contained in this page.
    # @see Parser#paths
    def paths
        @cache[:paths] ||= parser ? parser.paths : []
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
        @cache[:document] ||= (parser.nil? ? Nokogiri::HTML( body ) : parser.document)
    end

    # @note Will preserve caches for elements which have been externally modified.
    # @return   [Page]  `self` with caches cleared.
    def clear_cache
        [:links, :forms, :cookies, :headers ].each do |type|
            next if @has_custom_elements.include? type
            # Remove the association to this page before clearing the elements
            # from cache to make it easier on the GC.
            (@cache[type] || []).each { |e| e.page = nil }
        end

        @cache.delete_if { |k, _| !@has_custom_elements.include? k }
        self
    end

    def prepare_for_report
        # We want a hard clear, that's why we don't call #clear_cache.
        @cache.clear

        # If we're dealing with binary data remove it before storing.
        if !text?
            response.body = nil
            self.body     = nil
        end

        @dom.digest      = nil
        @dom.skip_states = nil

        self
    end

    # @return   [Boolean]
    #   `true` if the page contains client-side code, `false` otherwise.
    def has_script?
        return @has_javascript if !@has_javascript.nil?

        if !response.headers.content_type.to_s.start_with?( 'text/html' ) ||
            !text? || !document
            return @has_javascript = false
        end

        # First check, quick and simple.
        return @has_javascript = true if document.css( 'script' ).any?

        # Check for event attributes, if there are any then there's JS to be
        # executed.
        Browser::Javascript.events.flatten.each do |event|
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
        return false if !response
        response.text?
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
        end.merge(@cache)
    end
    alias :to_hash :to_h

    def persistent_hash
        digest.persistent_hash
    end

    def hash
        digest.hash
    end

    def ==( other )
        hash == other.hash
    end

    def eql?( other )
        self == other
    end

    def dup
        self.class.new to_initialization_options
    end

    def to_initialization_options
        h = {}
        [:body, :cookiejar, :element_audit_whitelist, :metadata].each do |m|
            h[m] = try_dup( instance_variable_get( "@#{m}".to_sym ) )
            h.delete( m ) if !h[m]
        end

        [:links, :forms, :cookies, :headers ].each do |type|
            next if !@has_custom_elements.include?( type )
            h[type] = @cache[type]

            if !h[type] || h[type].empty?
                h.delete( type )
                next
            end

            h[type] = h[type].map { |e| c = e.dup; c.page = nil; c }
        end

        h[:response] = response

        h[:dom] = dom.to_h.inject({}) { |dh, (k,v)| dh[k] = try_dup( v ); dh }
        h
    end

    def _dump( _ )
        Marshal.dump( to_initialization_options )
    end

    def self._load( data )
        new( Marshal.load( data ) )
    end

    private

    def digest
        element_hashes = []
        [:links, :forms, :cookies, :headers].each do |type|
            next if !@has_custom_elements.include?( type ) || !(list = @cache[type])
            element_hashes |= list.map(&:hash)
        end

        "#{dom.playable_transitions.hash}:#{body.hash}#{element_hashes.sort}"
    end

    [:url, :response, :cookiejar, :element_audit_whitelist, :metadata].each do |attribute|
        attr_writer attribute
    end

    def paths=( paths )
        @cache[:paths] = paths
    end

    def assign_page_to_elements( list )
        list.map do |e|
            e.page = self
            store_nonce_to_metadata e
            restore_nonce_from_metadata e
            e
        end.freeze
    end

    def store_nonce_to_metadata( element )
        ensure_metadata_nonces( element )

        return if !element.respond_to?(:has_nonce?) || !element.has_nonce?

        @metadata[element.type][:nonces][element.id.persistent_hash] =
            element.nonce_name
    end

    def restore_nonce_from_metadata( element )
        ensure_metadata_nonces( element )

        return if !element.respond_to?(:nonce_name=) || element.has_nonce?

        element.nonce_name = @metadata[element.type][:nonces][element.id.persistent_hash]
    end

    def ensure_metadata_nonces( element )
        @metadata[element.type] ||= {}
        @metadata[element.type][:nonces] ||= {}
    end

    def try_dup( v )
        v.dup rescue v
    end

end
end
