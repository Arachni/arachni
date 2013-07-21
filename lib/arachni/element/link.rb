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

require Arachni::Options.dir['lib'] + 'element/base'

module Arachni::Element

LINK = 'link'

class Link < Arachni::Element::Base

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

        self.method = :get

        @original = self.inputs.dup.freeze
    end

    # @return   [Hash]
    #   Simple representation of self in the form of `{ {#action} => {#inputs} }`.
    def simple
        { self.action => self.inputs }
    end

    # @return   [String]    Unique link ID.
    def id
        query_vars = self.class.parse_query_vars( self.action )
        "#{@audit_id_url}::#{self.method}::#{query_vars.merge( self.inputs ).keys.compact.sort.to_s}"
    end

    def id_from( type = :auditable )
        query_vars = self.class.parse_query_vars( self.action )
        "#{@audit_id_url}::#{self.method}::#{query_vars.merge( self.send( type ) ).keys.compact.sort.to_s}"
    end

    # @return   [String]
    #   Absolute URL with a merged version of {#action} and {#inputs} as a query.
    def to_s
        query_vars = self.class.parse_query_vars( self.action )
        uri = uri_parse( self.action )
        uri.query = query_vars.merge( self.inputs ).map { |k, v| "#{k}=#{v}" }.join( '&' )
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

            new( url: url, action: href, inputs: parse_query_vars( href ) )
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
        vars = inputs.keys.compact.sort.to_s

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
