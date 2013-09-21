=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require Arachni::Options.dir['lib'] + 'element/base'

module Arachni::Element

LINK = 'link'

class Link < Arachni::Element::Base

    include Capabilities::Refreshable

    #
    # Creates a new Link element from a URL or more complex data.
    #
    # @param    [String]    url
    #   {#url Owner URL} -- URL of the page which contains the link.
    # @param    [String, Hash]    raw
    #   If empty, the owner URL will be treated as the {#action actionable} URL
    #   and {#auditable} inputs will be extracted from its query component.
    #
    #   If a {String} is passed, it will be treated as the actionable
    #   URL and auditable inputs will be extracted from its query component.
    #
    #   If a `Hash` is passed, it will look for an {#action actionable} URL
    #   `String` in the following keys:
    #
    #   * `'href'`
    #   * `:href`
    #   * `'action'`
    #   * `:action`
    #
    #   and for an {#auditable} inputs `Hash` in:
    #
    #   * `'vars'`
    #   * `:vars`
    #   * `'inputs'`
    #   * `:inputs`
    #
    #   these should contain inputs in `name => value` pairs.
    #
    #   If the `Hash` doesn't contain any of the following keys, its contents
    #   will be used as {#auditable} inputs instead and `url` will be used as
    #   the actionable URL.
    #
    #   If no inputs have been provided it will try to extract some from the
    #   actionable URL, if empty inputs (empty `Hash`) have been provided the
    #   URL will not be parsed and the Link will instead be configured without
    #   any auditable inputs/vectors.
    #
    def initialize( url, raw = {} )
        super( url, raw )

        if !@raw || @raw.empty?
            self.action = self.url
        elsif raw.is_a?( String )
            self.action = @raw
        elsif raw.is_a?( Hash )
            keys = raw.keys
            has_input_hash  = (keys & ['vars', :vars, 'inputs', :inputs]).any?
            has_action_hash = (keys & ['href', :href, 'action', :action]).any?

            if !has_input_hash && !has_action_hash
                self.auditable = @raw
            else
                self.auditable = @raw['vars'] || @raw[:vars] || @raw['inputs'] || @raw[:inputs]
            end
            self.action = @raw['href'] || @raw[:href] || @raw['action'] || @raw[:action]
        end

        self.auditable = self.class.parse_query_vars( self.action ) if !self.auditable || self.auditable.empty?

        if @raw.is_a?( String )
            @raw = {
                action: self.action,
                inputs: self.auditable
            }
        end

        self.method = 'get'

        @orig = self.auditable.dup
        @orig.freeze
    end

    # @return   [Hash]
    #   Simple representation of self in the form of `{ {#action} => {#auditable} }`.
    def simple
        { self.action => self.auditable }
    end

    # @return   [String]    Unique link ID.
    def id
        query_vars = self.class.parse_query_vars( self.action )
        "#{@audit_id_url}::#{self.method}::#{query_vars.merge( self.auditable ).keys.compact.sort.to_s}"
    end

    def id_from( type = :auditable )
        query_vars = self.class.parse_query_vars( self.action )
        "#{@audit_id_url}::#{self.method}::#{query_vars.merge( self.send( type ) ).keys.compact.sort.to_s}"
    end

    # @return   [String]
    #   Absolute URL with a merged version of {#action} and {#auditable} as a query.
    def to_s
        query_vars = self.class.parse_query_vars( self.action )
        uri = uri_parse( self.action )
        uri.query = query_vars.merge( self.auditable ).map { |k, v| "#{k}=#{v}" }.join( '&' )
        uri.to_s
    end

    # @return [String]  'link'
    def type
        Arachni::Element::LINK
    end

    def self.encode( str )
        URI.encode( str )
    end

    def self.decode( str )
        URI.decode( str )
    end

    #
    # Extracts links from an HTTP response.
    #
    # @param   [Typhoeus::Response]    response
    #
    # @return   [Array<Link>]
    #
    def self.from_response( response )
        url = response.effective_url
        [new( url, parse_query_vars( url ) )] | from_document( url, response.body )
    end

    #
    # Extracts links from a document.
    #
    # @param    [String]    url
    #   URL of the document -- used for path normalization purposes.
    # @param    [String, Nokogiri::HTML::Document]    document
    #
    # @return   [Array<Link>]
    #
    def self.from_document( url, document )
        document = Nokogiri::HTML( document.to_s ) if !document.is_a?( Nokogiri::HTML::Document )
        base_url =  begin
            document.search( '//base[@href]' )[0]['href']
        rescue
            url
        end

        document.search( '//a' ).map do |link|
            c_link = {}
            c_link['href'] = to_absolute( link['href'], base_url )
            next if !c_link['href']

            new( url, c_link['href'] )
        end.compact
    end

    #
    # Extracts inputs from a URL query.
    #
    # @param    [String]    url
    #
    # @return   [Hash]
    #
    def self.parse_query_vars( url )
        return {} if !url

        parsed = uri_parse( url )
        return {} if !parsed

        query = parsed.query
        return {} if !query || query.empty?

        query.to_s.split( '&' ).inject( {} ) do |h, pair|
            name, value = pair.split( '=' )
            h[name.to_s] = value.to_s
            h
        end
    end

    # @see Base#action=
    def action=( url )
        v = super( url )
        @audit_id_url = self.action.split( '?' ).first.to_s.split( ';' ).first
        v
    end

    def audit_id( injection_str = '', opts = {} )
        vars = auditable.keys.compact.sort.to_s

        str = ''
        str << "#{@auditor.fancy_name}:" if !opts[:no_auditor] && !orphan?

        str << "#{@audit_id_url}:" + "#{self.type}:#{vars}"
        str << "=#{injection_str.to_s}" if !opts[:no_injection_str]
        str << ":timeout=#{opts[:timeout]}" if !opts[:no_timeout]

        str
    end

    private
    def http_request( opts, &block )
        self.method.downcase.to_s != 'get' ?
            http.post( self.action, opts, &block ) : http.get( self.action, opts, &block )
    end

end
end

Arachni::Link = Arachni::Element::Link
