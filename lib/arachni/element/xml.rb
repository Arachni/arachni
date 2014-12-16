=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

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
    include Capabilities::WithSource
    include Capabilities::Analyzable

    class Error < Arachni::Element::Error
        class MissingSource < Error
        end
    end

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

        fail Error::MissingSource if !@source

        self.inputs = (self.inputs || {}).merge( options[:inputs] || {} )
        if self.inputs.empty?
            self.inputs = self.class.parse_inputs( @source )
        end

        @default_inputs = self.inputs.dup.freeze
    end

    # Overrides {Capabilities::Mutable#each_mutation} to handle XML-specific
    # limitations.
    #
    # @param (see Capabilities::Mutable#each_mutation)
    # @return (see Capabilities::Mutable#each_mutation)
    # @yield (see Capabilities::Mutable#each_mutation)
    # @yieldparam (see Capabilities::Mutable#each_mutation)
    #
    # @see Capabilities::Mutable#each_mutation
    def each_mutation( payload, opts = {}, &block )
        opts.delete( :fuzz_names )
        super( payload, opts, &block )
    end

    # @return   [String]
    #   XML formatted {#inputs}.
    def to_xml
        doc = Nokogiri::XML( source )
        inputs.each do |path, content|
            doc.css( path ).each do |node|
                node.content = content
            end
        end

        doc.to_xml
    end
    def to_s
        to_xml
    end

    # @return   [Hash]
    #   Simple representation of self in the form of `{ {#action} => {#inputs} }`.
    def simple
        { self.action => self.inputs }
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

    def dup
        super.tap { |e| e.source = @source }
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
            doc = doc.is_a?( Nokogiri::XML ) ? doc : Nokogiri::XML( doc )

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
        opts.delete :parameters
        opts[:body]   = ::URI.encode_www_form_component( self.to_xml )
        opts[:method] = self.http_method
        http.request( self.action, opts, &block )
    end

end
end

Arachni::XML = Arachni::Element::XML
