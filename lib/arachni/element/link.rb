=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'base'

module Arachni::Element

class Link < Base
    include Capabilities::Analyzable
    include Capabilities::Refreshable

    require_relative 'link/dom'

    # @return   [Nokogiri::XML::Element]
    attr_accessor :node

    # @return   [DOM]
    attr_accessor :dom

    # @param    [Hash]    options
    # @option   options [String]    :url
    #   URL of the page which includes the link.
    # @option   options [String]    :action
    #   Link URL -- defaults to `:url`.
    # @option   options [Hash]    :inputs
    #   Query parameters as `name => value` pairs. If none have been provided
    #   they will automatically be extracted from {#action}.
    def initialize( options )
        super( options )

        if options[:inputs]
            self.inputs = options[:inputs]
        else
            self.inputs = self.class.parse_query_vars( self.action )
        end

        self.method = :get
        self.node   = options[:node]
        self.dom    = DOM.new( parent: self ) if @node

        @default_inputs = self.inputs.dup.freeze
    end

    def node=( n )
        @node = n.is_a?(String) ? self.class.unserialize_node( n ) : n
    end

    # @return   [Hash]
    #   Simple representation of self in the form of `{ {#action} => {#inputs} }`.
    def simple
        { self.action => self.inputs }
    end

    # @return   [String]    Unique link ID.
    def id
        id_from :inputs
    end

    def id_from( type = :inputs )
        "#{@audit_id_url}:#{self.method}:" <<
            "#{@query_vars.merge( self.send( type ) ).keys.compact.sort.to_s}"
    end

    def action=( url )
        v = super( url )
        @query_vars = parse_url_vars( v )
        @audit_id_url = v.split( '?' ).first.to_s
    end

    # @return   [String]
    #   Absolute URL with a merged version of {#action} and {#inputs} as a query.
    def to_s
        uri = uri_parse( self.action ).dup
        uri.query = @query_vars.merge( self.inputs ).
            map { |k, v| "#{encode_query_params(k)}=#{encode_query_params(v)}" }.
            join( '&' )
        uri.to_s
    end

    def encode_query_params( *args )
        self.class.encode_query_params( *args )
    end

    def self.encode_query_params( param )
        encode( encode( param ), '=' )
    end

    def encode( *args )
        self.class.encode( *args )
    end

    def self.encode( *args )
        URI.encode( *args )
    end

    def decode( *args )
        self.class.decode( *args )
    end

    def self.decode( *args )
        URI.decode( *args )
    end

    #
    # Extracts links from an HTTP response.
    #
    # @param   [Arachni::HTTP::Response]    response
    #
    # @return   [Array<Link>]
    #
    def self.from_response( response )
        url = response.url
        [new( url: url, inputs: parse_query_vars( url ) )] | from_document( url, response.body )
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
            href = to_absolute( link['href'], base_url )
            next if !href

            new(
                url:    url,
                action: href,
                inputs: parse_query_vars( href ),
                node:   Nokogiri::HTML.fragment( link.to_html ).css( 'a' ).first
            )
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
            name, value = pair.split( '=', 2 )
            h[name.to_s] = value.to_s
            h
        end
    end

    def self.unserialize_node( serialized_node )
        Nokogiri::HTML(serialized_node).css('a').first
    end

    def audit_id( injection_str = '', opts = {} )
        vars = inputs.keys.compact.sort.to_s

        str = ''
        str << "#{@auditor.class.name}:" if !opts[:no_auditor] && !orphan?

        str << "#{@audit_id_url}:" + "#{self.type}:#{vars}"
        str << "=#{injection_str.to_s}" if !opts[:no_injection_str]
        str << ":timeout=#{opts[:timeout]}" if !opts[:no_timeout]

        str
    end

    def dup
        new = super
        new.node = node.dup if node
        new.page = page
        new.dom  = dom.dup.tap { |d| d.parent = new } if @dom
        new
    end

    def hash
        "#{action}:#{method}:#{inputs.hash}}#{dom.hash}".hash
    end

    private

    def http_request( opts, &block )
        self.method.downcase.to_s != 'get' ?
            http.post( self.action, opts, &block ) : http.get( self.action, opts, &block )
    end

end
end

Arachni::Link = Arachni::Element::Link
