=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'base'
require_relative 'capabilities/with_node'

module Arachni::Element

# Represents an auditable link element
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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

        self.inputs     = (self.inputs || {}).merge( options[:inputs] || {} )
        @default_inputs = self.inputs.dup.freeze
    end

    # @return   [DOM]
    def dom
        return @dom if @dom
        return if !dom_data

        super
    end

    # @return   [Hash]
    #   Simple representation of self in the form of `{ {#action} => {#inputs} }`.
    def simple
        { self.action => self.inputs }
    end

    # @note Will {Arachni::Options.rewrite} the `url`.
    # @note Will update the {#inputs} from the URL query.
    #
    # @param   (see Capabilities::Submittable#action=)
    #
    # @return  (see Capabilities::Submittable#action=)
    def action=( url )
        rewritten   = uri_parse( url ).rewrite
        self.inputs = rewritten.query_parameters.merge( self.inputs || {} )

        super rewritten.without_query
    end

    # @return   [String]
    #   Absolute URL with a merged version of {#action} and {#inputs} as a query.
    def to_s
        uri = uri_parse( self.action ).dup
        uri.query = self.inputs.
            map { |k, v| "#{encode_query_params(k)}=#{encode_query_params(v)}" }.
            join( '&' )
        uri.to_s
    end

    # @param   (see .encode_query_params)
    # @return  (see .encode_query_params)
    #
    # @see .encode_query_params
    def encode_query_params( *args )
        self.class.encode_query_params( *args )
    end

    # @param   (see .encode)
    # @return  (see .encode)
    #
    # @see .encode
    def encode( *args )
        self.class.encode( *args )
    end

    # @param   (see .decode)
    # @return  (see .decode)
    #
    # @see .decode
    def decode( *args )
        self.class.decode( *args )
    end

    def coverage_id
        dom_data ? "#{super}:#{dom_data[:inputs].keys.sort}" : super
    end

    def id
        dom_data ? "#{super}:#{dom_data[:inputs].sort_by { |k,_| k }}" : super
    end

    def to_rpc_data
        data = super
        data.delete 'dom_data'
        data
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

                if (parsed_url = Arachni::URI( href ))
                    next if parsed_url.scope.out?
                end

                new(
                    url:    url.freeze,
                    action: href.freeze,
                    html:   link.to_html.freeze
                )
            end.compact
        end

        def encode_query_params( param )
            encode( encode( param ), '=' )
        end

        def encode( *args )
            ::URI.encode( *args )
        end

        def decode( *args )
            ::URI.decode( *args )
        end
    end


    private

    def dom_data
        return @dom_data if @dom_data
        return if @dom_data == false
        return if !node

        @dom_data ||= (DOM.data_from_node( node ) || false)
    end

    def http_request( opts, &block )
        self.method != :get ?
            http.post( self.action, opts, &block ) :
            http.get( self.action, opts, &block )
    end

end
end

Arachni::Link = Arachni::Element::Link
