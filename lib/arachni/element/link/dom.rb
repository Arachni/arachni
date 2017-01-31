=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative '../dom'

module Arachni::Element
class Link

# Provides access to DOM operations for {Link links}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class DOM < DOM

    # Load and include all link-specific capability overrides.
    lib = "#{File.dirname( __FILE__ )}/#{File.basename(__FILE__, '.rb')}/capabilities/**/*.rb"
    Dir.glob( lib ).each { |f| require f }

    # Generic element capabilities.
    include Arachni::Element::Capabilities::WithNode
    include Arachni::Element::DOM::Capabilities::Locatable
    include Arachni::Element::DOM::Capabilities::Mutable
    include Arachni::Element::DOM::Capabilities::Inputtable
    include Arachni::Element::DOM::Capabilities::Auditable

    # Link-specific overrides.
    include Capabilities::Submittable

    # @return   [String, nil]
    #   URL fragment.
    #
    #   `http://test.com/stuff#/path/in/fragment?with-input=too` =>
    #   `/path/in/fragment?with-input=too`
    attr_reader :fragment

    # @return   [String, nil]
    #   Path extracted from the {#fragment}.
    #
    #   `http://test.com/stuff#/path/in/fragment?with-input=too` =>
    #   `/path/in/fragment`
    attr_reader :fragment_path

    # @return   [String, nil]
    #   Query extracted from the {#fragment}.
    #
    #   `http://test.com/stuff#/path/in/fragment?with-input=too` =>
    #   `with-input=too`
    attr_reader :fragment_query

    def initialize(*)
        super

        prepare_data_from_node
        @method = :get
    end

    # Loads the page with the {#inputs} in the {#fragment}.
    def trigger
        [ browser.goto( to_s, take_snapshot: false, update_transitions: false ) ]
    end

    def valid_input_name?( name )
        @valid_input_names.include? name
    end

    # @return   [String]
    #   URL including the DOM {#inputs}.
    def to_s
        "#{@action}##{fragment_path}?" << inputs.
            map { |k, v| "#{encode(k)}=#{encode(v)}" }.
            join( '&' )
    end

    def message_action
        "#{@action}##{fragment}"
    end

    def type
        self.class.type
    end
    def self.type
        :link_dom
    end

    def self.data_from_node( node )
        fragment_path = fragment = nil

        href = node.attributes['href'].to_s
        return if !href.include? '#'

        fragment = href.split( '#', 2 ).last
        fragment_path, fragment_query = fragment.split( '?', 2 )

        inputs = uri_parse_query( "?#{fragment_query}" )
        return if inputs.empty?

        {
            inputs:         inputs,
            fragment:       fragment.freeze,
            fragment_path:  fragment_path.freeze,
            fragment_query: fragment_query.freeze,
        }
    end

    def hash
        to_s.hash
    end

    private

    def prepare_data_from_node
        return if !(data = self.class.data_from_node( node ))

        @valid_input_names = data[:inputs].keys

        self.inputs     = data[:inputs]
        @default_inputs = self.inputs.dup.freeze
        @fragment       = data[:fragment]
        @fragment_path  = data[:fragment_path]
        @fragment_query = data[:fragment_query]
    end

    def prepare_browser( browser, options )
        @browser = browser
        browser.javascript.custom_code = options[:custom_code]
        browser.javascript.taint       = options[:taint]
    end

end

end
end
