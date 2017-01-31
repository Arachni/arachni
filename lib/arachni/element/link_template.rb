=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'base'

module Arachni::Element

# Represents an auditable link element whose inputs have been extracted based
# on an externally provided template.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class LinkTemplate < Base
    require_relative 'link_template/dom'

    # Load and include all link-template-specific capability overrides.
    lib = "#{File.dirname( __FILE__ )}/#{File.basename(__FILE__, '.rb')}/capabilities/**/*.rb"
    Dir.glob( lib ).each { |f| require f }

    # Generic element capabilities.
    include Arachni::Element::Capabilities::WithNode
    include Arachni::Element::Capabilities::Mutable
    include Arachni::Element::Capabilities::Submittable
    include Arachni::Element::Capabilities::Analyzable

    # LinkTemplate-specific overrides.
    include Capabilities::WithDOM
    include Capabilities::Inputtable
    include Capabilities::Auditable

    include Arachni::Element::Capabilities::Auditable::Buffered
    include Arachni::Element::Capabilities::Auditable::LineBuffered

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

    def id
        dom_data ? "#{super}:#{dom_data[:inputs].sort_by { |k,_| k }}" : super
    end

    def to_rpc_data
        data = super
        data.delete 'dom_data'

        return data if !@template

        data.merge!( 'template' => @template.source )
        data['initialization_options']['template'] = data['template']

        data
    end

    class <<self

        def from_rpc_data( data )
            if data['initialization_options']['template']
                data['initialization_options']['template'] =
                    Regexp.new( data['initialization_options']['template'] )
            end

            if data['template']
                data['template'] = Regexp.new( data['template'] )
            end

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

            links = from_parser( Arachni::Parser.new( response ) , templates )

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
        # {Arachni::OptionGroups::Audit#link_templates templates} from a
        # document.
        #
        # @param    [Arachni::Parser]    parser
        # @param    [Array<Regexp>]    templates
        #
        # @return   [Array<LinkTemplate>]
        def from_parser( parser, templates = Arachni::Options.audit.link_templates )
            return [] if templates.empty?

            parser.document.nodes_by_name( :a ).map do |link|
                next if too_big?( link['href'] )
                next if !(href = to_absolute( link['href'], parser.base ))

                template, inputs = extract_inputs( href, templates )
                next if !template && !self::DOM.data_from_node( link )

                if (parsed_url = Arachni::URI( href ))
                    next if parsed_url.scope.out?
                end

                new(
                    url:      parser.url,
                    action:   href.freeze,
                    inputs:   inputs || {},
                    template: template,
                    source:   link.to_html.freeze
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
            Link.encode string
        end

        def decode( *args )
            Link.decode( *args )
        end

        def type
            :link_template
        end
    end

    private

    def http_request( opts, &block )
        opts.delete :parameters

        self.method != :get ?
            http.post( to_s, opts, &block ) :
            http.get( to_s, opts, &block )
    end

end
end

Arachni::LinkTemplate = Arachni::Element::LinkTemplate
