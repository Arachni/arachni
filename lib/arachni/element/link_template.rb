=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'base'
require_relative 'capabilities/with_dom'

module Arachni::Element

# Represents an auditable link element whose inputs have been extracted based
# on an externally provided template.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class LinkTemplate < Base
    require_relative 'link_template/dom'

    include Capabilities::WithNode
    include Capabilities::WithDOM
    include Capabilities::Analyzable

    INVALID_INPUT_DATA = [
        # Protocol URLs require a // which we can't preserve.
        '://'
    ]

    # @return   [Regexp]
    #   Regular expressions with named captures, serving as templates used to
    #   identify and manipulate inputs in {#action}.
    attr_reader :template

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

        @template = options[:template]

        if options[:inputs]
            self.inputs = options[:inputs]
        else
            if @template
                _, inputs = self.class.extract_inputs( self.action, [@template] )
                self.inputs = inputs if inputs
            else
                @template, inputs = self.class.extract_inputs( self.action )

                if @template
                    self.inputs = inputs
                end
            end
        end

        self.inputs ||= {}
        @default_inputs = self.inputs.dup.freeze
    end

    # @return   [DOM]
    def dom
        return @dom if @dom
        return if !dom_data

        super
    end

    # @param    [String]    name
    #   Input name.
    #
    # @return   [Bool]
    #   `true` if the `name` can be found as a named capture in {#template},
    #   `false` otherwise.
    def valid_input_name?( name )
        return if !@template
        @template.names.include? name
    end

    # @param    [String]    data
    #   Input data.
    #
    # @return   [Bool]
    #   `true` if the `data` don't contain strings specified in
    #   #{INVALID_INPUT_DATA}, `false` otherwise.
    #
    # @see INVALID_INPUT_DATA
    def valid_input_data?( data )
        !INVALID_INPUT_DATA.find { |c| data.include? c }
    end

    # @return   [Hash]
    #   Simple representation of self in the form of `{ {#action} => {#inputs} }`.
    def simple
        { self.action => self.inputs }
    end

    # @return   [String]
    #   URL updated with the configured {#inputs}.
    def to_s
        return self.action if self.inputs.empty?

        self.action.sub_in_groups(
            @template,
            inputs.inject({}) { |h, (k, v)| h[k] = encode(v); h }
        )
    end

    def encode( string )
        self.class.encode( string )
    end

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
        return data if !@template

        data.merge!( 'template' => @template.source )
        data['initialization_options'][:template] = data['template']
        data.delete 'dom_data'
        data
    end

    class <<self

        def from_rpc_data( data )
            data['template'] = Regexp.new( data['template'] ) if data['template']
            super data
        end

        # Extracts links from an HTTP response.
        #
        # @param   [Arachni::HTTP::Response]    response
        # @param    [Array<Regexp>]    templates
        #
        # @return   [Array<Link>]
        def from_response( response, templates = Arachni::Options.audit.link_templates )
            url = response.url

            links = from_document( url, response.body, templates )

            template, inputs = extract_inputs( url, templates )
            if template
                links << new(
                    url:      url.freeze,
                    action:   url.freeze,
                    inputs:   inputs,
                    template: template
                )
            end

            links
        end

        # Extracts link with inputs based on the provided
        # {Arachni::OptionGroups::Scope#path_input_templates templates} from a
        # document.
        #
        # @param    [String]    url
        #   URL of the document -- used for path normalization purposes.
        # @param    [String, Nokogiri::HTML::Document]    document
        # @param    [Array<Regexp>]    templates
        #
        # @return   [Array<LinkTemplate>]
        def from_document( url, document, templates = Arachni::Options.audit.link_templates )
            return [] if templates.empty?

            document = Nokogiri::HTML( document.to_s ) if !document.is_a?( Nokogiri::HTML::Document )
            base_url = begin
                document.search( '//base[@href]' )[0]['href']
            rescue
                url
            end

            document.search( '//a' ).map do |link|
                next if !(href = to_absolute( link['href'], base_url ))

                template, inputs = extract_inputs( href, templates )
                next if !template && !DOM.data_from_node( link )

                new(
                    url:      url.freeze,
                    action:   href.freeze,
                    inputs:   inputs || {},
                    template: template,
                    html:     link.to_html.freeze
                )
            end.compact
        end

        # Extracts inputs from a URL based on the given templates.
        #
        # @param    [String]           url
        # @param    [Array<Regexp>]    templates
        #
        # @return   [Array[Regexp, Hash]]
        #   Matched template and inputs.
        def extract_inputs( url, templates = Arachni::Options.audit.link_templates )
            return [] if !url || templates.empty?

            templates.each do |template|
                if (match = url.scan_in_groups( template )).any?
                    return [
                        template,
                        match.inject({}){ |h, (k, v)| h[k] = decode(v); h }
                    ]
                end
            end

            []
        end

        def encode( string )
            URI.encode( URI.encode( URI.encode( string, ';' ) ), '/' )
        end

        def decode( *args )
            URI.decode( *args )
        end

        def type
            :link_template
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
        opts.delete :parameters

        self.method != :get ?
            http.post( to_s, opts, &block ) :
            http.get( to_s, opts, &block )
    end

end
end

Arachni::LinkTemplate = Arachni::Element::LinkTemplate
