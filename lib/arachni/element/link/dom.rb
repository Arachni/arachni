=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni::Element
class Link

# Provides access to DOM operations for {Link links}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class DOM < Capabilities::Auditable::DOM

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

        if node
            @fragment = valid_attributes[:href].split( '#', 2 ).last
            @fragment_path, @fragment_query = @fragment.split( '?', 2 )
        end

        self.inputs     = parent.parse_query( "?#{fragment_query}" )
        @default_inputs = self.inputs.dup.freeze
    end

    # @return   [Watir::Anchor]
    def locate
        browser.watir.a( valid_attributes )
    end

    # Loads the page with the {#inputs} in the {#fragment}.
    def trigger
        browser.load to_s
    end

    # @return   [String]    URL including the DOM {#inputs}.
    def to_s
        "#{parent}##{fragment_path}?" << inputs.
            map { |k, v| "#{parent.encode_query_params(k)}=#{parent.encode_query_params(v)}" }.
            join( '&' )
    end

    def hash
        to_s.hash
    end

    private

    def all_valid_attributes
        @all_valid_attributes ||=
            Set.new( Arachni::Page::DOM::Transition.valid_element_attributes_for( :a ) )
    end

    def prepare_browser( browser, options )
        @browser = browser
        browser.javascript.custom_code = options[:custom_code]
    end

end

end
end
