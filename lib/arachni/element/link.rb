=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'base'
require_relative 'capabilities/with_node'

module Arachni::Element

# Represents an auditable link element
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Link < Base
    require_relative 'link/dom'

    include Capabilities::WithNode
    include Capabilities::WithDOM
    include Capabilities::Analyzable
    include Capabilities::Refreshable

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

        @default_inputs = self.inputs.dup.freeze
    end

    # @return   [DOM]
    def dom
        return @dom if @dom
        return if !node || @skip_dom

        # Check if the DOM has any auditable inputs and only initialize it
        # if it does.
        if DOM.data_from_node( node )
            return super
        else
            @skip_dom = true
        end

        nil
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

    # @note Will {.rewrite} the `url`.
    #
    # @param    (see Capabilities::Submittable#action=)
    # @@return  (see Capabilities::Submittable#action=)
    def action=( url )
        v = super( self.class.rewrite( url ) )

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

    def encode( *args )
        self.class.encode( *args )
    end

    def decode( *args )
        self.class.decode( *args )
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

    class <<self

        # Extracts links from an HTTP response.
        #
        # @param   [Arachni::HTTP::Response]    response
        #
        # @return   [Array<Link>]
        def from_response( response )
            url = response.url
            [new( url: url )] | from_document( url, response.body )
        end

        # Extracts links from a document.
        #
        # @param    [String]    url
        #   URL of the document -- used for path normalization purposes.
        # @param    [String, Nokogiri::HTML::Document]    document
        #
        # @return   [Array<Link>]
        def from_document( url, document )
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
                    url:    url.freeze,
                    action: href.freeze,
                    html:   link.to_html.freeze
                )
            end.compact
        end

        # Extracts inputs from a URL query.
        #
        # @param    [String]    url
        #
        # @return   [Hash]
        def parse_query_vars( url )
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

        # @param    [String]    url
        # @param    [Hash<Regexp => String>]    rules
        #   Regular expression and substitution pairs.
        #
        # @return  [String]
        #   Rewritten URL.
        def rewrite( url, rules = Arachni::Options.scope.link_rewrites )
            rules.each do |args|
                if (rewritten = url.gsub( *args )) != url
                    return rewritten
                end
            end

            url
        end

        def encode_query_params( param )
            encode( encode( param ), '=' )
        end

        def encode( *args )
            URI.encode( *args )
        end

        def decode( *args )
            URI.decode( *args )
        end
    end


    private

    def http_request( opts, &block )
        self.method.downcase.to_s != 'get' ?
            http.post( self.action, opts, &block ) :
            http.get( self.action, opts, &block )
    end

end
end

Arachni::Link = Arachni::Element::Link
