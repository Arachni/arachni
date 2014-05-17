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

    # @return   [String]
    #   {#action} updated with the the DOM {#inputs}.
    def to_s
        "#{@action}#" + fragment.sub_in_groups(
            @template,
            inputs.inject({}) { |h, (k, v)| h[k] = encode(v); h }
        )
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
        URI.encode( string, ';/' )
    end

    def decode( *args )
        LinkTemplate.decode( *args )
    end

    def type
        self.class.type
    end

    def self.type
        :link_template_dom
    end

    def prepare_data_from_node
        return if !(data = self.class.data_from_node( node ))

        self.inputs = data[:inputs]
        @template   = data[:template]
        @fragment   = data[:fragment]

        @default_inputs = self.inputs.dup.freeze
    end

    def self.data_from_node( node )
        fragment = node.attributes['href'].to_s.split( '#', 2 ).last.to_s
        return if fragment.empty?

        template, inputs = extract_inputs( fragment )
        return if !template

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
