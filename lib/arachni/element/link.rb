=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'base'

module Arachni::Element

# Represents an auditable link element
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Link < Base
    require_relative 'link/dom'

    # Load and include all link-specific capability overrides.
    lib = "#{File.dirname( __FILE__ )}/#{File.basename(__FILE__, '.rb')}/capabilities/**/*.rb"
    Dir.glob( lib ).each { |f| require f }

    # Generic element capabilities.
    include Arachni::Element::Capabilities::Analyzable
    include Arachni::Element::Capabilities::Refreshable

    # Link-specific overrides.
    include Capabilities::WithDOM
    include Capabilities::Submittable
    include Capabilities::Auditable

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

    # @return   [Hash]
    #   Simple representation of self in the form of `{ {#action} => {#inputs} }`.
    def simple
        { self.action => self.inputs }
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
                    source: link.to_html.freeze
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

    def http_request( opts, &block )
        self.method != :get ?
            http.post( self.action, opts, &block ) :
            http.get( self.action, opts, &block )
    end

end
end

Arachni::Link = Arachni::Element::Link
