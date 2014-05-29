=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni::Element
class LinkTemplate

# Provides access to DOM operations for {LinkTemplate link templates}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class DOM < Base
    include Capabilities::Auditable::DOM

    # @return   [String, nil]
    #   URL fragment.
    #
    #   `http://test.com/stuff#/path/in/fragment?with-input=too` =>
    #   `/path/in/fragment?with-input=too`
    attr_reader :fragment

    # @return    [Regexp]
    #   Regular expressions with named captures, serving as templates used to
    #   identify and manipulate inputs in {#action}.
    attr_reader :template

    def initialize(*)
        super

        prepare_data_from_node
        @method = :get
    end

    # Loads #{to_s}.
    def trigger
        browser.goto to_s, take_snapshot: false
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

    # @return   [String]
    #   {#action} updated with the the DOM {#inputs}.
    def to_s
        "#{@action}#" + fragment.sub_in_groups( @template, inputs )
    end

    def action
        "#{@action}##{fragment}"
    end

    def extract_inputs( *args )
        self.class.extract_inputs( *args )
    end
    def self.extract_inputs( url, templates = Arachni::Options.audit.link_template_doms )
        LinkTemplate.extract_inputs( url, templates )
    end

    def encode( string )
        self.class.encode( string )
    end

    def self.encode( string )
        string
    end

    def decode( *args )
        self.class.decode( *args )
    end

    def self.decode( *args )
        Link.decode( *args )
    end

    def type
        self.class.type
    end

    def self.type
        :link_template_dom
    end

    def prepare_data_from_node
        return if !(data = self.class.data_from_node( node ))

        @template   = data[:template]
        self.inputs = data[:inputs]
        @fragment   = data[:fragment]

        @default_inputs = self.inputs.dup.freeze
    end

    def self.data_from_node( node )
        href = node.attributes['href'].to_s
        return if !href.include? '#'

        fragment = href.split( '#', 2 ).last.to_s
        return if fragment.empty?

        fragment = Link.decode( fragment )
        template, inputs = extract_inputs( fragment )
        return if !template || inputs.empty?

        {
            inputs:   inputs,
            template: template,
            fragment: fragment
        }
    end

    def hash
        to_s.hash
    end

    def to_rpc_data
        super.merge( 'template' => @template.to_s )
    end

    def self.from_rpc_data( data )
        super data.merge( 'template' => Regexp.new( data['template'] ) )
    end

    private

    def prepare_browser( browser, options )
        @browser = browser
        browser.javascript.custom_code = options[:custom_code]
        browser.javascript.taint       = options[:taint]
    end

end

end
end
