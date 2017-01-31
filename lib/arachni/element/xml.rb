=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'base'

module Arachni::Element

# Represents an auditable XML element
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class XML < Base
    # Load and include all JSON-specific capability overrides.
    lib = "#{File.dirname( __FILE__ )}/#{File.basename(__FILE__, '.rb')}/capabilities/**/*.rb"
    Dir.glob( lib ).each { |f| require f }

    include Arachni::Element::Capabilities::Auditable
    include Arachni::Element::Capabilities::Auditable::Buffered
    include Arachni::Element::Capabilities::Auditable::LineBuffered
    include Arachni::Element::Capabilities::Submittable
    include Arachni::Element::Capabilities::Analyzable
    include Arachni::Element::Capabilities::WithSource

    # XML-specific overrides.
    include Capabilities::Inputtable
    include Capabilities::Mutable

    # @param    [Hash]    options
    # @option   options [String]    :url
    #   URL of the page which includes the link.
    # @option   options [String]    :action
    #   Link URL -- defaults to `:url`.
    # @option   options [String]    :source
    #   XML data, to be parsed into inputs.
    #
    # @raise    [Error::MissingSource]
    #   On missing `:source`.
    def initialize( options )
        self.http_method = options[:method] || :post

        super( options )

        fail Arachni::Element::Capabilities::WithSource::Error::MissingSource if !@source

        @inputs = options[:inputs] || {}
        if @inputs.empty?
            # The ivar needs to be set first because it's used as an input name
            # validator by the setter later on.
            @inputs = self.class.parse_inputs( @source )
            self.inputs = @inputs
        end

        @default_inputs = self.inputs.dup.freeze
    end

    # @return   [String]
    #   XML formatted {#inputs}.
    #
    #   If a {#transform_xml} callback has been set, it will return its value.
    def to_xml
        doc = Arachni::Parser.parse_xml( source ).dup

        inputs.each do |path, content|
            doc.css( path ).each do |node|
                node.content = content
            end
        end

        @transform_xml ? @transform_xml.call( doc.to_xml ) : doc.to_xml
    end

    # @param    [Block] block
    #   Callback to intercept {#to_xml}'s return value.
    def transform_xml( &block )
        @transform_xml = block
    end

    def to_s
        to_xml
    end

    # @return   [Hash]
    #   Simple representation of self in the form of `{ {#action} => {#inputs} }`.
    def simple
        { self.action => self.inputs }
    end

    # @see .encode
    def encode( *args )
        self.class.encode( *args )
    end

    # @see .decode
    def decode( *args )
        self.class.decode( *args )
    end

    def dup
        super.tap { |e| e.source = @source }
    end

    def to_rpc_data
        d = super
        d.delete 'transform_xml'
        d
    end

    def marshal_dump
        d = super
        d.delete :@transform_xml
        d
    end

    class <<self

        # No-op
        def encode( v )
            v
        end

        # No-op
        def decode( v )
            v
        end

        # Extracts XML elements from an HTTP request.
        #
        # @param   [Arachni::HTTP::Request]    request
        #
        # @return   [XML, nil]
        def from_request( url, request )
            return if !request.body.is_a?( String ) || request.body.empty?
            return if too_big?( request.body )

            data = parse_inputs( request.body )
            return if data.empty?

            new(
                url:    url,
                action: request.url,
                method: request.method,
                inputs: data,
                source: request.body
            )
        end

        def parse_inputs( doc )
            doc = doc.is_a?( Nokogiri::XML ) ? doc : Arachni::Parser.parse_xml( doc )

            inputs = {}
            doc.traverse do |node|
                if node.is_a?( Nokogiri::XML::Text ) && node.children.empty? &&
                    node.parent.children.size == 1

                    inputs[node.css_path] = node.content
                end

                if node.respond_to? :attributes
                    node.attributes.each do |_, attribute|
                        inputs[attribute.css_path] = attribute.content
                    end
                end
            end

            inputs
        end

    end

    private

    def http_request( opts, &block )
        opts = opts.dup
        opts.delete :parameters
        opts.merge!(
            headers: {
                'Content-Type' => 'application/xml'
            }
        )

        opts[:body]   = self.to_xml
        opts[:method] = self.http_method
        http.request( self.action, opts, &block )
    end

end
end

Arachni::XML = Arachni::Element::XML
