=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

# It holds page data like elements, cookies, headers, etc...
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Page
    include Utilities

    class Error < Arachni::Error
    end

    require_relative 'page/dom'
    require_relative 'page/scope'

    # @param    [String]    url
    #   URL to fetch.
    # @param    [Hash]  opts
    # @option  opts    [Integer]   :precision  (2)
    #   How many times to request the page and examine changes between requests.
    #   Used tp identify nonce tokens etc.
    # @option  opts    [Hash]  :http
    #   HTTP {HTTP::Client#get request} options.
    # @param    [Block] block
    #   Block to which to pass the page object. If given, the request will be
    #   performed asynchronously. If no block is given, the page will be fetched
    #   synchronously and be returned by this method.
    #
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

    # @param    [HTTP::Response]    response
    #   HTTP response to parse.
    #
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
    # @option options  [Array<Cookie>]    :cookie_jar
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

        data[:cookie_jar] ||= []

        data[:response][:request] = Arachni::HTTP::Request.new( data[:response][:request] )
        data[:response]           = Arachni::HTTP::Response.new( data[:response] )

        new data
    end

    ELEMENTS = [
        :links, :forms, :cookies, :headers, :link_templates, :jsons, :xmls,
        :ui_inputs, :ui_forms
    ]

    METADATA = [ :nonce_name, :skip_dom ]

    # @return       [DOM]
    #   DOM snapshot.
    attr_accessor   :dom

    # @return       [HTTP::Response]
    #   HTTP response.
    attr_reader     :response

    # @return       [Hash]
    #
    # @private
    attr_reader     :cache

    # @return       [Hash]
    #   Holds page data that will need to persist between {#clear_cache} calls
    #   and other utility data.
    attr_reader     :metadata

    # @return       [Set<Integer>]
    #   Audit whitelist based on {Element::Capabilities::Auditable#coverage_hash}.
    #
    # @see  #update_element_audit_whitelist
    # @see  #audit_element?
    # @see  Check::Auditor#skip?
    attr_reader     :element_audit_whitelist

    # Needs either a `:parser` or a `:response` or user provided data.
    #
    # @param    [Hash]  options
    #   Hash from which to set instance attributes.
    # @option options  [Array<HTTP::Response>, HTTP::Response]    :response
    #   HTTP response of the page -- or array of responses for the page for
    #   content refinement.
    # @option options  [Parser]    :parser
    #   An instantiated {Parser}.
    def initialize( options )
        fail ArgumentError, 'Options cannot be empty.' if options.empty?
        options = options.dup

        @cache = {}

        @do_not_audit_elements = options.delete(:do_not_audit_elements)

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

    # @return   [Scope]
    def scope
        @scope = Scope.new( self )
    end

    # @return   [Object]
    #   Object which performed the {#request} which lead to this page.
    def performer
        request.performer
    end

    # @return   [Arachni::URI]
    def parsed_url
        Arachni::URI( url )
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

    def parser=( p )
        @cache[:parser] = p
    end

    # @param    [Array<Element::Capabilities::Auditable, Integer>]    list
    #   Audit whitelist based on {Element::Capabilities::Auditable elements} or
    #   {Element::Capabilities::Auditable#coverage_hash}s.
    #
    # @return   [Set]   {#element_audit_whitelist}
    #
    # @see  #element_audit_whitelist
    # @see  Check::Auditor#skip?
    def update_element_audit_whitelist( list )
        [list].flatten.each do |e|
            @element_audit_whitelist <<
                (e.is_a?( Integer ) ? e : e.coverage_hash )
        end
    end

    # @param    [Element::Capabilities::Auditable, Integer]    element
    #   Element or {Element::Capabilities::Auditable#coverage_hash}.
    #
    # @return   [Bool]
    #   `true` if the element should be audited, `false` otherwise.
    #
    # @see  #element_audit_whitelist
    # @see  Check::Auditor#skip?
    def audit_element?( element )
        return if @do_not_audit_elements
        return true if @element_audit_whitelist.empty?
        @element_audit_whitelist.include?(
            element.is_a?( Integer ) ? element : element.coverage_hash
        )
    end

    # It forces {#audit_element?} to always returns false.
    def do_not_audit_elements
        @do_not_audit_elements = true
    end

    # @return    [HTTP::Request]
    #   HTTP request.
    def request
        response.request
    end

    # @return    [String]
    #   URL of the page.
    def url
        @url ||= @response.url
    end

    # @return    [String]
    #   URL of the page.
    def code
        return 0 if !@code && !response
        @code ||= response.code
    end

    # @return    [Hash]
    #   {#url URL} query parameters.
    def query_vars
        @cache[:query_vars] ||= uri_parse_query( url )
    end

    # @return    [String]
    #   HTTP response body.
    def body
        return '' if !@body && !@response
        @body ||= response.body
    end

    # @param    [String]    string
    #   Page body.
    def body=( string )
        @has_javascript = nil
        clear_cache

        @body = string.to_s.freeze
    end

    ELEMENTS.each do |type|
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
    def cookie_jar
        @cookie_jar ||= (parser ? parser.cookie_jar : [])
    end

    # @return    [Array<String>]
    #   Paths contained in this page.
    #
    # @see Parser#paths
    def paths
        @cache[:paths] ||= (parser ? parser.paths : [])
    end

    # @return   [Platform]
    #   Applicable platforms for the page.
    def platforms
        Platform::Manager[url]
    end

    # @return   [Array<Element::Base>]
    #   All page elements.
    def elements
        ELEMENTS.map { |type| send( type ) }.flatten
    end

    # @return   [Array<Element::Base>]
    #   All page elements that are within the scope of the scan.
    def elements_within_scope
        ELEMENTS.map do |type|
            next if !Options.audit.element? type
            send( type ).select { |e| e.scope.in? }
        end.flatten.compact
    end

    # @return    [String]
    #   The request method that returned the page
    def method( *args )
        return super( *args ) if args.any?
        response.request.method
    end

    # @return   [Arachni::Parser::Document]
    #   Parsed {#body HTML} document.
    def document
        @cache[:document] ||= (parser.nil? ?
            Arachni::Parser.parse( body ) :
            parser.document)
    end

    # @note Will preserve caches for elements which have been externally modified.
    #
    # @return   [Page]
    #   `self` with caches cleared.
    def clear_cache
        ELEMENTS.each do |type|
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

        @cookie_jar.clear if @cookie_jar

        @dom.digest      = nil
        @dom.skip_states = nil

        self
    end

    # @return   [Boolean]
    #   `true` if the page contains client-side code, `false` otherwise.
    def has_script?
        return @has_javascript if !@has_javascript.nil?

        if !response.headers.content_type.to_s.start_with?( 'text/html' ) || !text?
            return @has_javascript = false
        end

        dbody = body.downcase

        # First check, quick and simple.
        if dbody.include?( '<script' ) || dbody.include?( 'javascript:' )
            return @has_javascript = true
        end

        # Check for event attributes, if there are any then there's JS to be
        # executed.
        Browser::Javascript.events.flatten.each do |event|
            return @has_javascript = true if dbody.include?( "#{event}=" )
        end

        @has_javascript = false
    end

    # @param    [String, Symbol,Array<String, Symbol>]  tags
    #   Element tag names.
    #
    # @return   [Boolean]
    #   `true` if the page contains any of the given elements, `false` otherwise.
    def has_elements?( *tags )
        return if !text?

        tags.flatten.each do |tag|
            tag = tag.to_s

            next if !body.has_html_tag?( tag )

            return false if !document
            return true  if document.nodes_by_name( tag ).any?
        end

        false
    end

    # @return   [Boolean]
    #   `true` if the body of the page is text-base, `false` otherwise.
    def text?
        return false if !response
        response.text?
    end

    # @return   [String]
    #   Title of the page.
    def title
        document.nodes_by_name( 'title' ).first.text rescue nil
    end

    # @return   [Hash]
    #   Converts the page data to a hash.
    def to_h
        skip = [:@document, :@do_not_audit_elements, :@has_custom_elements, :@scope]

        instance_variables.inject({}) do |h, iv|
            next h if skip.include? iv

            h[iv.to_s.gsub( '@', '').to_sym] = try_dup( instance_variable_get( iv ) )
            h
        end.merge(@cache).tap { |h| h.delete :parser }
    end
    alias :to_hash :to_h

    def to_s
        "#<#{self.class}:#{object_id} @url=#{@url.inspect} @dom=#{@dom}>"
    end
    alias :inspect :to_s

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

    def update_metadata
        ELEMENTS.each do |type|
            next if !@cache[type]

            @cache[type].each { |e| store_to_metadata e }
        end
    end

    def reload_metadata
        ELEMENTS.each do |type|
            next if !@cache[type]

            @cache[type].each { |e| restore_from_metadata e }
        end
    end

    def import_metadata( other, metas = METADATA )
        [metas].flatten.each do |meta|
            other.metadata.each do |element_type, data|
                @metadata[element_type] ||= {}
                @metadata[element_type][meta.to_s] ||= {}
                @metadata[element_type][meta.to_s].merge!( data[meta.to_s] )
            end
        end

        reload_metadata

        self
    end

    def to_initialization_options( deep = true )
        h = {}
        h[:body] = @body if @body

        [:cookie_jar, :element_audit_whitelist, :metadata].each do |m|
            h[m] = instance_variable_get( "@#{m}".to_sym )

            if deep
                h[m] = try_dup( h[m] )
            end

            h.delete( m ) if !h[m]
        end

        ELEMENTS.each do |type|
            next if !@has_custom_elements.include?( type )
            h[type] = @cache[type]

            if !h[type] || h[type].empty?
                h.delete( type )
                next
            end

            h[type] = h[type].map { |e| c = e.dup; c.page = nil; c }
        end

        h[:response] = response
        h[:do_not_audit_elements] = @do_not_audit_elements

        h[:dom] = dom.to_h.keys.inject({}) do |dh, k|
            dh[k] = dom.send( k )

            if deep
                dh[k] = try_dup( dh[k] )
            end

            dh
        end

        h
    end

    # @return   [Hash]
    #   Data representing this instance that are suitable the RPC transmission.
    def to_rpc_data
        data        = to_initialization_options( false ).my_stringify_keys(false)
        data['dom'] = dom.to_rpc_data
        data['element_audit_whitelist'] = element_audit_whitelist.to_a
        data['response'] = data['response'].to_rpc_data

        (ELEMENTS - [:headers]).map(&:to_s).each do |e|
            next if !data[e]
            data[e] = send(e).map(&:to_rpc_data)
        end

        data.delete 'cookie_jar'

        data
    end

    # @param    [Hash]  data
    #   {#to_rpc_data}
    #
    # @return   [Page]
    def self.from_rpc_data( data )
        dom = data.delete('dom')
        normalized_data = {}
        data.each do |name, value|

            value = case name
                        when 'response'
                            HTTP::Response.from_rpc_data( value )

                        when *ELEMENTS.map(&:to_s)
                            value.map do |e|
                                Element.type_to_class( name[0...-1].to_sym ).from_rpc_data( e )
                            end.to_a

                        else
                            value
                    end

            normalized_data[name.to_sym] = value
        end

        instance = new( normalized_data )
        instance.instance_variable_set(
            '@dom', DOM.from_rpc_data( dom.merge( page: instance ) )
        )
        instance
    end

    def _dump( _ )
        Marshal.dump( to_initialization_options( false ) )
    end

    def self._load( data )
        new( Marshal.load( data ) )
    end

    private

    def digest
        element_hashes = []
        ELEMENTS.each do |type|
            next if !@has_custom_elements.include?( type ) || !(list = @cache[type])
            element_hashes |= list.map(&:hash)
        end

        "#{dom.playable_transitions.hash}:#{body.hash}#{element_hashes.sort}"
    end

    [:url, :response, :cookie_jar, :element_audit_whitelist, :metadata].each do |attribute|
        attr_writer attribute
    end

    def paths=( paths )
        @cache[:paths] = paths
    end

    def assign_page_to_elements( list )
        list.map do |e|
            e.page = self

            store_to_metadata e
            restore_from_metadata e

            e
        end.freeze
    end

    def store_to_metadata( element )
        METADATA.each do |meta|
            next if !element.respond_to?(meta)

            ensure_metadata( element, meta )
            @metadata[element.type.to_s][meta.to_s][element.coverage_hash] ||=
                element.send(meta)
        end
    end

    def restore_from_metadata( element )
        METADATA.each do |meta|
            next if !element.respond_to?( "#{meta}=" )

            ensure_metadata( element, meta )
            element.send(
                "#{meta}=",
                @metadata[element.type.to_s][meta.to_s][element.coverage_hash]
            )
        end
    end

    def ensure_metadata( element, meta )
        @metadata[element.type.to_s] ||= {}
        @metadata[element.type.to_s][meta.to_s] ||= {}
    end

    def try_dup( v )
        v.dup rescue v
    end

end
end
