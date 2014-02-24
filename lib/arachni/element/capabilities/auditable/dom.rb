=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'output'

module Arachni
module Element::Capabilities
module Auditable

class DOM
    include Auditable::Output
    include Auditable

    extend Forwardable

    attr_reader   :parent
    attr_accessor :browser

    # @!method with_browser_cluster( &block )
    def_delegator :auditor, :with_browser_cluster

    # @!method with_browser( &block )
    def_delegator :auditor, :with_browser

    # @!method auditor
    def_delegator :parent,  :auditor

    # @!method page
    def_delegator :parent,  :page

    # @!method node
    def_delegator :parent,  :node

    # @!method type
    def_delegator :parent,  :type

    # @!method ==
    def_delegator :parent,  :==

    def initialize( parent )
        @parent        = parent
        @audit_options = {}
    end

    def element
        @element ||= locate
    end

    # Overrides {Capabilities::Mutable#each_mutation} to handle DOM limitations.
    #
    # @param (see Capabilities::Mutable#each_mutation)
    # @return (see Capabilities::Mutable#each_mutation)
    # @yield (see Capabilities::Mutable#each_mutation)
    # @yieldparam (see Capabilities::Mutable#each_mutation)
    #
    # @see Capabilities::Mutable#each_mutation
    def each_mutation( injection_str, opts = {} )
        super( injection_str, opts ) do |mutation|
            # DOM operations don't support nulls.
            next if (mutation.format & Format::NULL) != 0
            yield mutation
        end
    end

    # @param  [Hash]  options
    # @param  [Block]  block    Callback to be passed the evaluated {Page}.
    def submit( options = {}, &block )
        with_browser do |browser|
            prepare_browser( browser, options )
            trigger

            block.call browser.to_page.tap { |p| p.request.performer = self }

            @element = nil
            @browser = nil
        end
        nil
    end

    # Locates the element in the page.
    #
    # @abstract
    def locate
        fail NotImplementedError
    end

    # Triggers the event on the subject {#element}.
    #
    # @abstract
    def trigger
        fail NotImplementedError
    end

    def hash
        inputs.hash
    end

    private

    def prepare_browser( browser, options )
        @browser = browser
        browser.javascript.custom_code = options[:custom_code]

        browser.load page
    end

    def all_valid_attributes
        @all_valid_attributes ||=
            Set.new( Arachni::Page::DOM::Transition.valid_element_attributes_for( type ) )
    end

    def valid_attributes
        node.attributes.inject({}) do |h, (k, v)|
            attribute = k.gsub( '-' ,'_' ).to_sym
            next h if !all_valid_attributes.include? attribute

            h[attribute] = v.to_s
            h
        end
    end

    def on_complete( page, &block )
        block.call page, page.request.performer
    end

end

end
end
end
