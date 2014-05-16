=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require Arachni::Options.paths.lib + 'element/base'

module Arachni::Element

# Represents an auditable link element whose inputs have been extracted based
# on an externally provided template.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class LinkTemplate < Base
    include Capabilities::Analyzable

    # @return    [Regexp]
    #   Regular expressions with named captures, serving as templates used to
    #   identify and manipulate inputs in {#action}.
    attr_reader   :template

    # require_relative 'link_template/dom'
    #
    # # @return     [DOM]
    # attr_accessor :dom

    # @return     [String]
    #   Original HTML code for that element.
    attr_accessor :html

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

        self.html   = options[:html]
        self.method = :get

        @default_inputs = self.inputs.dup.freeze
    end

    # # @return   [DOM]
    # def dom
    #     return @dom if @dom
    #     return if !@html || @skip_dom
    #
    #     # Check if the DOM has any auditable inputs and only initialize it
    #     # if it does.
    #     if DOM.data_from_node( node )
    #         @dom = DOM.new( parent: self )
    #     else
    #         @skip_dom = true
    #     end
    #
    #     @dom
    # end

    # @return [Nokogiri::XML::Element]
    def node
        return if !@html
        Nokogiri::HTML.fragment( @html.dup ).children.first
    end

    # @return   [Hash]
    #   Simple representation of self in the form of `{ {#action} => {#inputs} }`.
    def simple
        { self.action => self.inputs }
    end

    # @return   [String]
    #   URL updated with the configured {#inputs}.
    def to_s
        return self.action if !@template

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

    def dup
        new = super
        new.page = page
        # new.dom  = dom.dup.tap { |d| d.parent = new } if @dom
        new
    end

    def hash
        # "#{action}:#{method}:#{inputs.hash}}#{dom.hash}".hash
        "#{action}:#{method}:#{inputs.hash}}".hash
    end

    def to_rpc_data
        data = super.merge( 'template' => @template.source )
        data['initialization_options'][:template] = data['template']
        data
    end

    class <<self

        def from_rpc_data( data )
            data['template'] = Regexp.new( data['template'] )
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
                next if (href = to_absolute( link['href'], base_url ))

                template, inputs = extract_inputs( href, templates )
                next if !template

                new(
                    url:      url.freeze,
                    action:   href.freeze,
                    inputs:   inputs,
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

            exception_jail false do
                templates.each do |template|
                    if (match = url.scan_in_groups( template )).any?
                        return [template, match]
                    end
                end
            end

            []
        end

        def encode( string )
            URI.encode(
                URI.encode( string, ';/' ),
                "a-zA-Z0-9\\-\\.\\_\\~\\!\\$\\&\\'\\(\\)\\*\\+\\,\\=\\:\\@\\%"
            )
        end

        def decode( *args )
            URI.decode( *args )
        end
    end

    private

    def http_request( opts, &block )
        self.method.downcase.to_s != 'get' ?
            http.post( to_s, opts, &block ) :
            http.get( to_s, opts, &block )
    end

end
end

Arachni::LinkTemplate = Arachni::Element::LinkTemplate
